resource "kubernetes_job" "archive_download" {
  for_each = {
    #media = { src_path = "media", dest_path = "media" }
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

resource "kubernetes_job" "archive_upload" {
  for_each = {
    # time format: "2012-11-01 22:08:41", or null for current time
    radial2014logs   = { path = "mc/servers/radialcraft/logs", time = "2014-08-20 14:28:47" }
    radial2014server = { path = "mc/servers/radialcraft/server", time = "2014-07-31 21:49:00" }
    radial2014worlds = { path = "mc/servers/radialcraft/worlds", time = "2014-07-30 01:35:55" }
    documents2017    = { path = "documents", time = "2017-02-12 17:10:47" }
    projects2018     = { path = "projects/stale", time = "2018-05-23 15:00:40" }
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
        # Hacky jobqueue setup:
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "kubernetes.io/hostname"
                  operator = "In"
                  values   = ["pyrope"]
                }
              }
            }
          }
        }
        #affinity {
        #  node_affinity {
        #    preferred_during_scheduling_ignored_during_execution {
        #      weight = 50
        #      preference {
        #        match_expressions {
        #          key      = "topology.kubernetes.io/zone"
        #          operator = "In"
        #          values   = ["z-adw"]
        #        }
        #      }
        #    }
        #  }
        #}
        volume {
          name = "scratch"
          persistent_volume_claim {
            claim_name = module.storage.archive_scratch_pvc_name
          }
        }
        container {
          name  = "main"
          image = "docker.io/restic/restic@sha256:157243d77bc38be75a7b62b0c00453683251310eca414b9389ae3d49ea426c16"
          args = concat([
            "backup",
            "--exclude=lost+found",
            "--exclude=.nobackup",
            "--host=generic",
            "--one-file-system",
            "--read-concurrency=4",
            "--repo=b2:${local.globals.b2.archive.bucket}:/personal-restic",
            ], each.value.time != null ? ["--time=${each.value.time}"] : [], [
            "/data/${each.value.path}",
          ])
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
          # Hacky jobqueue setup:
          resources {
            requests = {
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
}

#resource "kubernetes_job" "archive_xfer" {
#  wait_for_completion = false
#  metadata {
#    name = "archive-xfer"
#    namespace = kubernetes_namespace.main.metadata[0].name
#    labels = { app = "archive-xfer" }
#  }
#  spec {
#    backoff_limit = 0
#    template {
#      metadata {
#        labels = { app = "archive-xfer" }
#      }
#      spec {
#        restart_policy = "Never"
#        # Hacky jobqueue setup:
#        affinity {
#          node_affinity {
#            required_during_scheduling_ignored_during_execution {
#              node_selector_term {
#                match_expressions {
#                  key      = "kubernetes.io/hostname"
#                  operator = "In"
#                  values   = ["pyrope"]
#                }
#              }
#            }
#          }
#        }
#        #affinity {
#        #  node_affinity {
#        #    required_during_scheduling_ignored_during_execution {
#        #      node_selector_term {
#        #        match_expressions {
#        #          key      = "topology.kubernetes.io/zone"
#        #          operator = "NotIn"
#        #          values   = ["z-adw"]
#        #        }
#        #      }
#        #    }
#        #  }
#        #}
#        container {
#          name = "main"
#          image = "docker.io/restic/restic@sha256:157243d77bc38be75a7b62b0c00453683251310eca414b9389ae3d49ea426c16"
#          command = [
#            "sh",
#            "-c",
#            <<-EOF
#              set -o errexit -o nounset -o pipefail -o xtrace
#              srcrepo=b2:redactedbucket:skaia/stash-0/personal/media
#              destrepo=b2:redactedbucket:personal-restic
#              destpath=/data/media
#              restic -r "$srcrepo" snapshots --json > snapshots.json
#              n_snaps=$(jq length snapshots.json)
#              for snap_idx in $(seq 0 $((n_snaps-1))); do
#                n_paths=$(jq --argjson snap_idx "$snap_idx" '.[$snap_idx].paths|length' snapshots.json)
#                if [[ "$n_paths" -ne 1 ]]; then
#                  echo >&2 "snapshot number $snap_idx does not have exactly one path!"
#                  exit 1
#                fi
#                srcsnap=$(jq --argjson snap_idx "$snap_idx" -r '.[$snap_idx].id' snapshots.json)
#                srcpath=$(jq --argjson snap_idx "$snap_idx" -r '.[$snap_idx].paths[0]' snapshots.json)
#                snaptime=$(jq --argjson snap_idx "$snap_idx" -r '.[$snap_idx].time' snapshots.json)
#                snaptime=$${snaptime/T/ }
#                snaptime=$${snaptime%Z}
#                snaptime=$${snaptime%.*}
#                rm -rf "$destpath"
#                restic -r "$srcrepo" restore "$srcsnap:$srcpath" --target "$destpath"
#                restic -r "$destrepo" backup --host=generic --one-file-system --read-concurrency=4 --time="$snaptime" "$destpath"
#              done
#            EOF
#          ]
#          env_from {
#            secret_ref {
#              name = module.storage.archive_secret_name
#            }
#          }
#          # for restic
#          env {
#            name = "TZ"
#            value = "UTC"
#          }
#          # Hacky jobqueue setup:
#          resources {
#            requests = {
#              "squat.ai/render" = "1"
#            }
#            limits = {
#              "squat.ai/render" = "1"
#            }
#          }
#          volume_mount {
#            name = "workspace"
#            mount_path = "/data"
#          }
#        }
#        volume {
#          name = "workspace"
#          ephemeral {
#            volume_claim_template {
#              metadata {
#                labels = { app = "archive-xfer" }
#              }
#              spec {
#                access_modes       = ["ReadWriteOnce"]
#                storage_class_name = "blk-media0"
#                resources {
#                  requests = { storage = "40Gi" }
#                }
#              }
#            }
#          }
#        }
#      }
#    }
#  }
#}

resource "kubernetes_job" "sleep" {
  wait_for_completion = false
  metadata {
    name      = "sleep"
    namespace = kubernetes_namespace.main.metadata[0].name
    labels    = { app = "sleep" }
  }
  spec {
    backoff_limit = 0
    template {
      metadata {
        labels = { app = "sleep" }
      }
      spec {
        restart_policy = "Never"
        # Hacky jobqueue setup:
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "kubernetes.io/hostname"
                  operator = "In"
                  values   = ["pyrope"]
                }
              }
            }
          }
        }
        container {
          name    = "main"
          image   = "docker.io/busybox"
          command = ["sleep", "39600"]
          # Hacky jobqueue setup:
          resources {
            requests = {
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
}


resource "kubernetes_job" "delete_trash" {
  count               = 0
  wait_for_completion = false
  metadata {
    name      = "delete-trash"
    namespace = kubernetes_namespace.main.metadata[0].name
    labels    = { app = "delete-trash" }
  }
  spec {
    backoff_limit = 0
    template {
      metadata {
        labels = { app = "delete-trash" }
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
          name    = "main"
          image   = "docker.io/busybox"
          command = ["sh", "-c", "mv /scratch/trash /scratch/trash.deleting && mkdir /scratch/trash && rm -rf /scratch/trash.deleting"]
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
