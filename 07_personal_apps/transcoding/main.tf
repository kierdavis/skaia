terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "namespace" {
  type = string
}

variable "media_pvc_name" {
  type = string
}

variable "downloads_pvc_name" {
  type = string
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

module "image" {
  source         = "../../modules/container_image"
  repo_name      = "skaia-transcode"
  repo_namespace = local.globals.docker_hub.namespace
  src            = "${path.module}/image"
}

# Aim for 1.5 Mb/s bitrate - resulting video should occupy 660MB per hour of footage.

# To convert 10-bit HEVC to 8-bit AVC:
# ffmpeg \
#   -y \
#   -init_hw_device qsv=hw \
#   -filter_hw_device hw \
#   -i "$FILE" \
#   -vf format=nv12,hwupload=extra_hw_frames=64 \
#   -map 0 \
#   -c:a copy \
#   -c:s copy \
#   -c:v h264_qsv \
#   "$TMP_FILE"

resource "kubernetes_job" "main" {
  for_each = {
    foobar = "/net/skaia/media/foobar.mkv"
    #foobar = "/net/skaia/media/foobar.mkv"
  }
  metadata {
    name      = "transcode-${each.key}"
    namespace = var.namespace
    labels    = { app = "transcode", instance = each.key }
  }
  spec {
    backoff_limit = 0
    template {
      metadata {
        labels = { app = "transcode", instance = each.key }
      }
      spec {
        restart_policy = "Never"
        affinity {
          node_affinity {
            # Require a node with Intel QSV (all QSV versions include h.264 encoding).
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "kubernetes.io/hostname"
                  operator = "In"
                  values   = ["vantas", "pyrope"]
                }
              }
            }
          }
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              topology_key = "kubernetes.io/hostname"
              label_selector {
                match_expressions {
                  key      = "app"
                  operator = "In"
                  values   = ["transcode"]
                }
              }
            }
          }
        }
        volume {
          name = "media"
          persistent_volume_claim {
            claim_name = var.media_pvc_name
          }
        }
        volume {
          name = "downloads"
          persistent_volume_claim {
            claim_name = var.downloads_pvc_name
          }
        }
        container {
          name  = "main"
          image = module.image.tag
          command = [
            "bash", "-c",
            <<-EOS
              set -o errexit -o nounset -o pipefail
              vainfo --display drm --device /dev/dri/renderD128
              #ffmpeg -h encoder=h264_qsv
              TMP_FILE="$(dirname "$FILE")/transcodetmp.$(basename "$FILE")"
              ffmpeg \
                -y \
                -hwaccel qsv \
                -c:v h264_qsv \
                -i "$FILE" \
                -map 0 \
                -c:a copy \
                -c:s copy \
                -c:v h264_qsv \
                -b:v 1.5M \
                -bufsize 1M \
                "$TMP_FILE"
              rm -v "$FILE"
              mv -v "$TMP_FILE" "$FILE"
            EOS
          ]
          env {
            name  = "FILE"
            value = each.value
          }
          volume_mount {
            name       = "media"
            mount_path = "/net/skaia/media"
          }
          volume_mount {
            name       = "downloads"
            mount_path = "/net/skaia/torrent-downloads"
            read_only  = true
          }
          resources {
            requests = {
              cpu               = "1"
              memory            = "2Gi"
              "squat.ai/render" = "1"
            }
            limits = {
              "squat.ai/render" = "1"
            }
          }
        }
      }
    }
  }
  wait_for_completion = false
}
