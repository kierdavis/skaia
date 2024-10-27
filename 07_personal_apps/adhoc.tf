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

#resource "kubernetes_job" "sync_volumes" {
#  metadata {
#    name = "sync-volumes"
#    namespace = kubernetes_namespace.main.metadata[0].name
#    labels = { app = "sync-volumes" }
#  }
#  spec {
#    backoff_limit = 0
#    template {
#      metadata {
#        labels = { app = "sync-volumes" }
#      }
#      spec {
#        restart_policy = "Never"
#        volume {
#          name = "src"
#          persistent_volume_claim {
#            claim_name = "state-paperless-ngx-redis-0"
#          }
#        }
#        volume {
#          name = "dest"
#          persistent_volume_claim {
#            claim_name = "state-paperless-redis-0"
#          }
#        }
#        container {
#          name = "main"
#          image = "docker.io/eeacms/rsync"
#          args = [
#            "rsync",
#            "--acls",
#            "--archive",
#            "--hard-links",
#            "--verbose",
#            "--xattrs",
#            "/src/",
#            "/dest/",
#          ]
#          volume_mount {
#            name = "src"
#            mount_path = "/src"
#            read_only = true
#          }
#          volume_mount {
#            name = "dest"
#            mount_path = "/dest"
#            read_only = false
#          }
#        }
#      }
#    }
#  }
#  wait_for_completion = false
#}
