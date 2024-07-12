#resource "kubernetes_job" "transcode" {
#  metadata {
#    name = "transcode"
#    namespace = kubernetes_namespace.main.metadata[0].name
#    labels = { app = "transcode" }
#  }
#  spec {
#    backoff_limit = 0
#    template {
#      metadata {
#        labels = { app = "transcode" }
#      }
#      spec {
#        restart_policy = "Never"
#        affinity {
#          node_affinity {
#            # This node has a Skylake CPU while pyrope has a Broadwell.
#            required_during_scheduling_ignored_during_execution {
#              node_selector_term {
#                match_expressions {
#                  key      = "kubernetes.io/hostname"
#                  operator = "In"
#                  values   = ["vantas"]
#                }
#              }
#            }
#          }
#        }
#        volume {
#          name = "media"
#          persistent_volume_claim {
#            claim_name = module.storage.media_pvc_name
#          }
#        }
#        volume {
#          name = "downloads"
#          persistent_volume_claim {
#            claim_name = module.storage.downloads_pvc_name
#          }
#        }
#        container {
#          name = "main"
#          image = "nixos/nix"
#          command = [
#            "bash", "-c",
#            <<-EOS
#              set -o errexit -o nounset -o pipefail
#              mkdir -p /run/opengl-driver/lib/dri
#              ln -sf $(nix-build '<nixpkgs>' -A intel-media-driver --no-out-link)/lib/dri/iHD_drv_video.so /run/opengl-driver/lib/dri/iHD_drv_video.so
#              nix-env -i -A nixpkgs.ffmpeg-full -A nixpkgs.libva-utils
#              vainfo --display drm --device /dev/dri/renderD128
#              ffmpeg \
#                -y \
#                -init_hw_device qsv=hw \
#                -filter_hw_device hw \
#                -i '/net/skaia/media/foobar.mkv' \
#                -vf format=nv12,hwupload=extra_hw_frames=64 \
#                -map 0 \
#                -c:a copy \
#                -c:s copy \
#                -c:v h264_qsv \
#                '/net/skaia/media/foobar.out.mkv'
#            EOS
#          ]
#          volume_mount {
#            name       = "media"
#            mount_path = "/net/skaia/media"
#          }
#          volume_mount {
#            name       = "downloads"
#            mount_path = "/net/skaia/torrent-downloads"
#            read_only  = true
#          }
#          resources {
#            requests = {
#              cpu               = "1"
#              memory            = "2Gi"
#              "squat.ai/render" = "1"
#            }
#            limits = {
#              "squat.ai/render" = "1"
#            }
#          }
#        }
#      }
#    }
#  }
#  wait_for_completion = false
#}

#resource "kubernetes_job" "upload_takeout" {
#  metadata {
#    name = "upload-takeout"
#    namespace = kubernetes_namespace.main.metadata[0].name
#    labels = { app = "upload-takeout" }
#  }
#  spec {
#    backoff_limit = 0
#    template {
#      metadata {
#        labels = { app = "upload-takeout" }
#      }
#      spec {
#        restart_policy = "Never"
#        affinity {
#          node_affinity {
#            required_during_scheduling_ignored_during_execution {
#              node_selector_term {
#                match_expressions {
#                  key      = "topology.kubernetes.io/zone"
#                  operator = "In"
#                  values   = ["z-adw"]
#                }
#              }
#            }
#          }
#        }
#        volume {
#          name = "src"
#          persistent_volume_claim {
#            claim_name = module.storage.media_pvc_name
#          }
#        }
#        container {
#          name = "main"
#          image = "nixos/nix"
#          command = [
#            "bash", "-c",
#            <<-EOS
#              set -o errexit -o nounset -o pipefail
#              mkdir -p ~/.config/rclone
#              cat > ~/.config/rclone/rclone.conf <<-EOF
#              [archive-b2-inner]
#              type = b2
#              account = $B2_ACCOUNT_ID
#              key = $B2_ACCOUNT_KEY
#              [archive-b2]
#              type = alias
#              remote = archive-b2-inner:${local.globals.b2.archive.bucket}
#              EOF
#              nix-env -iA nixpkgs.rclone
#              rclone copyto --progress --bwlimit 1500k /src/tmp/takeout-20240528T202713Z.tar.lst.bz2.gpg archive-b2:google/takeout-redacted@example.net-20240528.tar.lst.bz2.gpg
#              rclone copyto --progress --bwlimit 1500k /src/tmp/takeout-20240528T202713Z.tar.bz2.gpg     archive-b2:google/takeout-redacted@example.net-20240528.tar.bz2.gpg
#            EOS
#          ]
#          volume_mount {
#            name = "src"
#            mount_path = "/src"
#            read_only = true
#          }
#          env_from {
#            secret_ref {
#              name = module.storage.archive_secret_name
#            }
#          }
#        }
#      }
#    }
#  }
#  wait_for_completion = false
#}
