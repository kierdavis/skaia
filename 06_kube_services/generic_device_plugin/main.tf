terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "kubernetes_daemonset" "main" {
  wait_for_rollout = false
  metadata {
    name      = "generic-device-plugin"
    namespace = "system"
    labels    = { "app.kubernetes.io/name" = "generic-device-plugin" }
  }
  spec {
    selector {
      match_labels = { "app.kubernetes.io/name" = "generic-device-plugin" }
    }
    strategy {
      type = "RollingUpdate"
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "generic-device-plugin" }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        priority_class_name              = "system-node-critical"
        restart_policy                   = "Always"
        termination_grace_period_seconds = 2
        toleration {
          effect   = "NoExecute"
          operator = "Exists"
        }
        toleration {
          effect   = "NoSchedule"
          operator = "Exists"
        }
        container {
          name  = "main"
          image = "docker.io/squat/generic-device-plugin@sha256:ba6f0b4cf6c858d6ad29ba4d32e4da11638abbc7d96436bf04f582a97b2b8821"
          args = [
            "--device",
            yamlencode({
              name = "render"
              groups = [{
                paths = [
                  { path = "/dev/dri/card0" },
                  { path = "/dev/dri/renderD128" },
                ]
              }]
              count = 4 # allow same device to be attached to up to N pods
            }),
          ]
          resources {
            requests = {
              cpu    = "1m"
              memory = "20Mi"
            }
            limits = {
              memory = "200Mi"
            }
          }
          port {
            name           = "http"
            container_port = 8080
          }
          security_context {
            privileged = true
          }
          volume_mount {
            name       = "device-plugin"
            mount_path = "/var/lib/kubelet/device-plugins"
          }
          volume_mount {
            name       = "dev"
            mount_path = "/dev"
          }
        }
        volume {
          name = "device-plugin"
          host_path {
            path = "/var/lib/kubelet/device-plugins"
          }
        }
        volume {
          name = "dev"
          host_path {
            path = "/dev"
          }
        }
      }
    }
  }
}
