resource "kubernetes_job" "archive_download" {
  for_each = {
    google = { src_path = "google", dest_path = "google" }
  }
  wait_for_completion = false
  metadata {
    name      = "archive-download-${each.key}"
    namespace = kubernetes_namespace.main.metadata[0].name
    labels    = { app = "archive-download", instance = each.key }
  }
  spec {
    backoff_limit = 0
    template {
      metadata {
        labels = { app = "archive-download", instance = each.key }
      }
      spec {
        restart_policy = "Never"
        affinity {
          node_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 50
              preference {
                match_expressions {
                  key      = "topology.kubernetes.io/zone"
                  operator = "In"
                  values   = ["z-adw"]
                }
              }
            }
          }
        }
        volume {
          name = "scratch"
          persistent_volume_claim {
            claim_name = module.storage.archive_scratch_pvc_name
          }
        }
        container {
          name  = "main"
          image = "docker.io/rclone/rclone@sha256:74c51b8817e5431bd6d7ed27cb2a50d8ee78d77f6807b72a41ef6f898845942b"
          args  = ["copy", ":b2:${local.globals.b2.archive.bucket}/${each.value.src_path}", "/scratch/downloaded/${each.value.dest_path}"]
          volume_mount {
            name       = "scratch"
            mount_path = "/scratch"
          }
          env_from {
            secret_ref {
              name = module.storage.archive_secret_name
            }
          }
          env {
            name  = "RCLONE_B2_ACCOUNT"
            value = "$(B2_ACCOUNT_ID)"
          }
          env {
            name  = "RCLONE_B2_KEY"
            value = "$(B2_ACCOUNT_KEY)"
          }
          security_context {
            run_as_user  = local.globals.personal_uid
            run_as_group = local.globals.personal_uid
          }
        }
      }
    }
  }
}

module "archive_extract_image" {
  source         = "../modules/container_image"
  repo_name      = "skaia-archive-extract"
  repo_namespace = local.globals.docker_hub.namespace
  src            = "${path.module}/archive_extract_image"
}

resource "kubernetes_job" "archive_extract" {
  for_each = {
    #takeout-lss = { path = "downloaded/google/takeout-redacted@example.net-20150812.tar.bz2", compressor = "pbzip2" }
  }
  wait_for_completion = false
  metadata {
    name      = "archive-extract-${each.key}"
    namespace = kubernetes_namespace.main.metadata[0].name
    labels    = { app = "archive-extract", instance = each.key }
  }
  spec {
    backoff_limit = 0
    template {
      metadata {
        labels = { app = "archive-extract", instance = each.key }
      }
      spec {
        restart_policy = "Never"
        affinity {
          node_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 50
              preference {
                match_expressions {
                  key      = "topology.kubernetes.io/zone"
                  operator = "In"
                  values   = ["z-adw"]
                }
              }
            }
          }
        }
        volume {
          name = "scratch"
          persistent_volume_claim {
            claim_name = module.storage.archive_scratch_pvc_name
          }
        }
        container {
          name  = "main"
          image = module.archive_extract_image.tag
          command = [
            "bash",
            "-c",
            "mkdir -p /scratch/${each.value.path}.dir && tar -vx -C /scratch/${each.value.path}.dir -f /scratch/${each.value.path} -I ${each.value.compressor}",
          ]
          volume_mount {
            name       = "scratch"
            mount_path = "/scratch"
          }
          security_context {
            run_as_user  = local.globals.personal_uid
            run_as_group = local.globals.personal_uid
          }
        }
      }
    }
  }
}

resource "kubernetes_job" "archive_upload" {
  for_each = {
    # time format: "2012-11-01 22:08:41", or "now"
    google-lss = { path = "accounts/google/redacted@example.net", time = "2015-08-12 00:00:00" }
  }
  wait_for_completion = false
  metadata {
    name      = "archive-upload-${each.key}"
    namespace = kubernetes_namespace.main.metadata[0].name
    labels    = { app = "archive-upload", instance = each.key }
  }
  spec {
    backoff_limit = 0
    template {
      metadata {
        labels = { app = "archive-upload", instance = each.key }
      }
      spec {
        restart_policy = "Never"
        affinity {
          node_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 50
              preference {
                match_expressions {
                  key      = "topology.kubernetes.io/zone"
                  operator = "In"
                  values   = ["z-adw"]
                }
              }
            }
          }
        }
        volume {
          name = "scratch"
          persistent_volume_claim {
            claim_name = module.storage.archive_scratch_pvc_name
          }
        }
        container {
          name  = "main"
          image = "docker.io/restic/restic@sha256:157243d77bc38be75a7b62b0c00453683251310eca414b9389ae3d49ea426c16"
          args = [
            "backup",
            "--exclude=lost+found",
            "--exclude=.nobackup",
            "--host=generic",
            "--one-file-system",
            "--read-concurrency=4",
            "--repo=b2:${local.globals.b2.archive.bucket}:/personal-restic",
            "--time=${each.value.time}",
            "/data/${each.value.path}",
          ]
          volume_mount {
            name       = "scratch"
            sub_path   = "staging"
            mount_path = "/data"
            read_only  = true
          }
          env_from {
            secret_ref {
              name = module.storage.archive_secret_name
            }
          }
          security_context {
            run_as_user  = local.globals.personal_uid
            run_as_group = local.globals.personal_uid
          }
        }
      }
    }
  }
}

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
