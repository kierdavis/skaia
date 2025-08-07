terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "system_namespace" {
  type = string
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

module "image" {
  source         = "../../modules/stamp_image"
  repo_name      = "skaia-debug"
  repo_namespace = local.globals.docker_hub.username
  flake          = "path:${path.module}/../..#kubeEssential.debug.image"
}

# TODO: resources
resource "kubernetes_daemonset" "main" {
  wait_for_rollout = false
  metadata {
    name      = "node-debug"
    namespace = var.system_namespace
    labels    = { "app.kubernetes.io/name" = "node-debug" }
  }
  spec {
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "100%"
      }
    }
    selector {
      match_labels = { "app.kubernetes.io/name" = "node-debug" }
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "node-debug" }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        host_network                     = true
        host_pid                         = true
        priority_class_name              = "system-node-critical"
        restart_policy                   = "Always"
        termination_grace_period_seconds = 1
        container {
          name  = "main"
          image = module.image.repo_tag
          security_context {
            privileged = true
          }
          volume_mount {
            name       = "host"
            mount_path = "/host"
          }
          volume_mount {
            name       = "tailscale-socket"
            mount_path = "/var/run/tailscale/tailscaled.sock"
          }
          resources {
            requests = { cpu = "1m", memory = "5Mi" }
            limits   = { memory = "4Gi" }
          }
        }
        volume {
          name = "host"
          host_path {
            path = "/"
          }
        }
        volume {
          name = "tailscale-socket"
          host_path {
            path = "/var/run/tailscale/tailscaled.sock"
          }
        }
        toleration {
          effect   = "NoExecute"
          operator = "Exists"
        }
        toleration {
          effect   = "NoSchedule"
          operator = "Exists"
        }
      }
    }
  }
}
