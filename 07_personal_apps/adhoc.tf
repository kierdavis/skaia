resource "kubernetes_job" "archive_download" {
  for_each = {
    #foobar = {
    #  src_snapshot = "d3df90e2"
    #  src_path = "/data/foo/bar"
    #  dest_pvc = module.storage.photography_pvc_name
    #  dest_path = "foo/bar"
    #}
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
          name = "dest"
          persistent_volume_claim {
            claim_name = each.value.dest_pvc
          }
        }
        container {
          name  = "main"
          image = "docker.io/restic/restic@sha256:157243d77bc38be75a7b62b0c00453683251310eca414b9389ae3d49ea426c16"
          args = [
            "restore",
            "--repo=b2:${var.b2_archive_bucket}:personal-restic",
            "--target=/dest/${each.value.dest_path}",
            "--verbose",
            "${each.value.src_snapshot}:${each.value.src_path}",
          ]
          volume_mount {
            name       = "dest"
            mount_path = "/dest"
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

resource "kubernetes_job" "archive_upload" {
  for_each = {
    # time format: "2012-11-01 22:08:41", or null for current time
    #takeout = { pvc_name = module.storage.media_pvc_name, pvc_path = ".nobackup/tmp/Takeout", mount_path = "/data/accounts/google/redacted@example.net", time = "2025-04-27 17:53:47" }
    #refern = { pvc_name = module.storage.media_pvc_name, pvc_path = ".nobackup/tmp/refern", mount_path = "/data/accounts/refern/redacted@example.net", time = null }
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
          name = "src"
          persistent_volume_claim {
            claim_name = each.value.pvc_name
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
            "--repo=b2:${var.b2_archive_bucket}:/personal-restic",
            "--verbose",
            ], each.value.time != null ? ["--time=${each.value.time}"] : [], [
            each.value.mount_path,
          ])
          volume_mount {
            name       = "src"
            sub_path   = each.value.pvc_path
            mount_path = each.value.mount_path
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
#        container {
#          name = "main"
#          image = "docker.io/restic/restic@sha256:157243d77bc38be75a7b62b0c00453683251310eca414b9389ae3d49ea426c16"
#          command = [
#            "sh",
#            "-c",
#            <<-EOF
#              set -o errexit -o nounset -o pipefail -o xtrace
#              srcrepo=b2:redactedbucket:skaia/personal-1
#              destrepo=b2:redactedbucket:personal-restic
#              restic -r "$srcrepo" snapshots --json > snapshots.json
#              n_snaps=$(jq length snapshots.json)
#              for snap_idx in $(seq 0 $((n_snaps-1))); do
#                n_paths=$(jq --argjson snap_idx "$snap_idx" '.[$snap_idx].paths|length' snapshots.json)
#                if [[ "$n_paths" -ne 1 ]]; then
#                  echo >&2 "snapshot number $snap_idx does not have exactly one path!"
#                  exit 1
#                fi
#                srcsnap=$(jq --argjson snap_idx "$snap_idx" -r '.[$snap_idx].id' snapshots.json)
#                if [[ "$srcsnap" = 29923395956e06f50bee884ebbd26fa6e40c1282671f0b3e95b7305ce4bcaca1 ]]; then
#                  continue  # already processed
#                fi
#                srcpath=$(jq --argjson snap_idx "$snap_idx" -r '.[$snap_idx].paths[0]' snapshots.json)
#                snaptime=$(jq --argjson snap_idx "$snap_idx" -r '.[$snap_idx].time' snapshots.json)
#                snaptime=$${snaptime/T/ }
#                snaptime=$${snaptime%Z}
#                snaptime=$${snaptime%.*}
#                case "$srcpath" in
#                  /net/skaia/projects) destpath=/data/projects ;;
#                  /net/skaia/media) destpath=/data/media ;;
#                  /net/skaia/documents) destpath=/data/documents ;;
#                  *) echo >&2 "unrecognised srcpath=$srcpath"; exit 1 ;;
#                esac
#                rm -rf "$destpath"
#                restic -r "$srcrepo" restore "$srcsnap:$srcpath" --target "$destpath"
#                mkdir -p "$destpath"  # in case snapshot contained no files
#                restic -r "$destrepo" backup --host=generic --one-file-system --read-concurrency=4 --time="$snaptime" "$destpath"
#                rm -rf "$destpath"
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
#                storage_class_name = "rbd-video0"
#                volume_mode        = "Filesystem"
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

#resource "kubernetes_job" "sleep" {
#  wait_for_completion = false
#  metadata {
#    name = "sleep"
#    namespace = kubernetes_namespace.main.metadata[0].name
#    labels = { app = "sleep" }
#  }
#  spec {
#    backoff_limit = 0
#    template {
#      metadata {
#        labels = { app = "sleep" }
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
#        container {
#          name = "main"
#          image = "docker.io/busybox"
#          command = ["sleep", "39600"]
#          # Hacky jobqueue setup:
#          resources {
#            requests = {
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
#}
#

#resource "kubernetes_persistent_volume_claim" "storage_grafana_0_tmp" {
#  metadata {
#    name = "storage-grafana-0-tmp"
#    namespace = "prometheus"
#  }
#  spec {
#    access_modes       = ["ReadWriteOnce"]
#    storage_class_name = "rbd-monitoring0"
#    volume_mode        = "Filesystem"
#    resources {
#      requests = { storage = "4Gi" }
#    }
#  }
#}

resource "kubernetes_job" "sync_volumes" {
  for_each = {
    #grafana = {
    #  namespace = "prometheus"
    #  src = kubernetes_persistent_volume_claim.storage_grafana_0_tmp.metadata[0].name
    #  dest = "storage-grafana-0"
    #}
  }
  metadata {
    name      = "sync-volumes-${each.key}"
    namespace = each.value.namespace
    labels    = { app = "sync-volumes", instance = each.key }
  }
  spec {
    backoff_limit = 0
    template {
      metadata {
        labels = { app = "sync-volumes", instance = each.key }
      }
      spec {
        restart_policy = "Never"
        volume {
          name = "src"
          persistent_volume_claim {
            claim_name = each.value.src
          }
        }
        volume {
          name = "dest"
          persistent_volume_claim {
            claim_name = each.value.dest
          }
        }
        container {
          name  = "main"
          image = "docker.io/eeacms/rsync"
          args = [
            "rsync",
            "--acls",
            "--archive",
            "--hard-links",
            "--verbose",
            "--xattrs",
            "/src/",
            "/dest/",
          ]
          volume_mount {
            name       = "src"
            mount_path = "/src"
            read_only  = true
          }
          volume_mount {
            name       = "dest"
            mount_path = "/dest"
            read_only  = false
          }
        }
      }
    }
  }
  wait_for_completion = false
}
