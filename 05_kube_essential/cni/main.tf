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
  repo_name      = "skaia-cni"
  repo_namespace = local.globals.docker_hub.username
  flake_output   = "./${path.module}/../..#kubeEssential.cni.image"
}

resource "kubernetes_service_account" "main" {
  metadata {
    name      = "cni"
    namespace = var.system_namespace
    labels    = { "app.kubernetes.io/name" = "cni" }
  }
}

resource "kubernetes_cluster_role" "main" {
  metadata {
    name   = "cni"
    labels = { "app.kubernetes.io/name" = "cni" }
  }
  rule {
    api_groups = [""]
    resources  = ["nodes", "services"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "main" {
  metadata {
    name   = "cni"
    labels = { "app.kubernetes.io/name" = "cni" }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.main.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.main.metadata[0].name
    namespace = kubernetes_service_account.main.metadata[0].namespace
  }
}

resource "kubernetes_daemonset" "main" {
  wait_for_rollout = false
  metadata {
    name      = "cni"
    namespace = var.system_namespace
    labels    = { "app.kubernetes.io/name" = "cni" }
  }
  spec {
    selector {
      match_labels = { "app.kubernetes.io/name" = "cni" }
    }
    strategy {
      type = "RollingUpdate"
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "cni" }
      }
      spec {
        automount_service_account_token  = true
        enable_service_links             = false
        host_network                     = true
        priority_class_name              = "system-node-critical"
        restart_policy                   = "Always"
        service_account_name             = kubernetes_service_account.main.metadata[0].name
        termination_grace_period_seconds = 1
        container {
          name  = "main"
          image = module.image.repo_tag
          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "spec.nodeName"
              }
            }
          }
          env {
            name  = "SERVICE_CIDRS"
            value = "${local.globals.kubernetes.svc_net.ipv4},${local.globals.kubernetes.svc_net.ipv6}"
          }
          env {
            name  = "RUST_LOG"
            value = "warn,skaia_cni=trace"
          }
          volume_mount {
            name       = "cni-config"
            mount_path = "/cni-config"
          }
          volume_mount {
            name       = "tailscale-socket"
            mount_path = "/var/run/tailscale/tailscaled.sock"
          }
        }
        volume {
          name = "cni-config"
          host_path {
            path = "/etc/cni/net.d"
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
