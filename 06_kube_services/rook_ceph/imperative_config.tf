module "imperative_config_image" {
  source         = "../../modules/stamp_image"
  repo_name      = "skaia-rook-ceph-imperative-config"
  repo_namespace = local.globals.docker_hub.username
  flake_output   = "./${path.module}/../..#kubeServices.rookCeph.imperativeConfigImage"
}

resource "kubernetes_job" "imperative_config" {
  depends_on          = [kubectl_manifest.cluster]
  wait_for_completion = true
  timeouts {
    create = "5m"
    update = "5m"
  }
  metadata {
    name      = "imperative-config"
    namespace = local.namespace
    labels    = { "app.kubernetes.io/name" = "imperative-config" }
  }
  spec {
    backoff_limit   = 0
    completions     = 1
    completion_mode = "NonIndexed"
    parallelism     = 1
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "imperative-config" }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        priority_class_name              = "system-cluster-critical"
        restart_policy                   = "Never"
        termination_grace_period_seconds = 30
        container {
          name  = "main"
          image = module.imperative_config_image.repo_tag
          env {
            name = "ROOK_CEPH_MON_HOST"
            value_from {
              secret_key_ref {
                name = "rook-ceph-config"
                key  = "mon_host"
              }
            }
          }
          env {
            name  = "CEPH_ARGS"
            value = "-m $(ROOK_CEPH_MON_HOST) -n client.admin -k /etc/ceph/admin-keyring-store/keyring"
          }
          env {
            name  = "RUST_LOG"
            value = "warn,rook_ceph_imperative_config=info"
          }
          volume_mount {
            name       = "etc-ceph"
            mount_path = "/etc/ceph"
            read_only  = true
          }
          volume_mount {
            name       = "keyring"
            mount_path = "/etc/ceph/admin-keyring-store"
            read_only  = true
          }
        }
        volume {
          name = "etc-ceph"
          projected {
            default_mode = "0644"
            sources {
              config_map {
                name = "rook-config-override"
                items {
                  key  = "config"
                  path = "ceph.conf"
                  mode = "0444"
                }
              }
            }
          }
        }
        volume {
          name = "keyring"
          secret {
            secret_name = "rook-ceph-admin-keyring"
          }
        }
      }
    }
  }
}
