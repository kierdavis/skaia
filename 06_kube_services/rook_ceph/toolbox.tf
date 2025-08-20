resource "kubernetes_deployment" "toolbox" {
  depends_on       = [kubectl_manifest.cluster]
  wait_for_rollout = false
  metadata {
    name      = "rook-ceph-tools"
    namespace = local.namespace
    labels = {
      "app.kubernetes.io/name" = "rook-ceph-tools"
      "app"                    = "rook-ceph-tools" # required by rook-ceph kubectl plugin
    }
  }
  spec {
    replicas = 1
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "100%"
        max_unavailable = "100%"
      }
    }
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "rook-ceph-tools"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "rook-ceph-tools"
          "app"                    = "rook-ceph-tools" # required by rook-ceph kubectl plugin
        }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 1
        container {
          name    = "rook-ceph-tools" # required by rook-ceph kubectl plugin
          image   = local.rook_image
          command = ["/usr/local/bin/toolbox.sh"]
          env {
            name = "ROOK_CEPH_USERNAME"
            value_from {
              secret_key_ref {
                name = "rook-ceph-mon"
                key  = "ceph-username"
              }
            }
          }
          volume_mount {
            name       = "ceph-config"
            mount_path = "/etc/ceph"
          }
          volume_mount {
            name       = "mon-endpoint-volume"
            mount_path = "/etc/rook"
          }
          volume_mount {
            name       = "ceph-admin-secret"
            mount_path = "/var/lib/rook-ceph-mon"
            read_only  = true
          }
          resources {
            requests = { cpu = "2m", memory = "5Mi" }
            limits   = { memory = "6Gi" }
          }
        }
        volume {
          name = "ceph-config"
          empty_dir {}
        }
        volume {
          name = "mon-endpoint-volume"
          config_map {
            name = "rook-ceph-mon-endpoints"
            items {
              key  = "data"
              path = "mon-endpoints"
            }
          }
        }
        volume {
          name = "ceph-admin-secret"
          secret {
            secret_name = "rook-ceph-mon"
            items {
              key  = "ceph-secret"
              path = "secret.keyring"
            }
          }
        }
      }
    }
  }
}
