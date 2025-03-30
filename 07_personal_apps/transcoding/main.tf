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

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

module "image" {
  source         = "../../modules/container_image_v2"
  repo_name      = "skaia-transcode"
  repo_namespace = local.globals.docker_hub.namespace
  src            = "${path.module}/image.nix"
}

resource "kubernetes_job" "hevc10_to_avc" {
  for_each = {
    #foo = "/net/skaia/media/foo.mkv"
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
            # Require a node that supports hardware AVC encoding.
            # None of my nodes support hardware HEVC Main 10 decoding, so we'll do that in software.
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "hwcaps.skaia.cloud/qsv"
                  operator = "NotIn"
                  values   = ["none", "cantiga", "clarkdale", "arrandale"]
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
        container {
          name  = "main"
          image = module.image.name_and_tag
          command = [
            "sh", "-c",
            <<-EOS
              set -o errexit -o nounset -o pipefail
              vainfo --display drm --device /dev/dri/renderD128
              DEST="/net/skaia/media/.nobackup/$${FILE#/net/skaia/media/}"
              mkdir -p "$(dirname "$DEST")"
              ffmpeg \
                -y \
                -init_hw_device vaapi=hw \
                -filter_hw_device hw \
                -i "$FILE" \
                -vf format=nv12,hwupload=extra_hw_frames=64 \
                -map 0 \
                -c:a copy \
                -c:s copy \
                -c:v h264_vaapi \
                -b:v 1.5M \
                -bufsize 1M \
                "$DEST"
              rm -v "$FILE"
              ln -sfT "$DEST" "$FILE"
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
