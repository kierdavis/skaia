terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "kubernetes_cluster_role" "main" {
  metadata {
    name   = "kube-network-policies"
    labels = { "app.kubernetes.io/name" = "kube-network-policies" }
  }
  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods"]
    verbs      = ["list", "watch"]
  }
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["networkpolicies"]
    verbs      = ["list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "main" {
  metadata {
    name   = "kube-network-policies"
    labels = { "app.kubernetes.io/name" = "kube-network-policies" }
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

resource "kubernetes_service_account" "main" {
  metadata {
    name      = "kube-network-policies"
    namespace = "system"
    labels    = { "app.kubernetes.io/name" = "kube-network-policies" }
  }
}

resource "kubernetes_daemonset" "main" {
  wait_for_rollout = false
  metadata {
    name      = "kube-network-policies"
    namespace = "system"
    labels    = { "app.kubernetes.io/name" = "kube-network-policies" }
  }
  spec {
    strategy {
      type = "RollingUpdate"
    }
    selector {
      match_labels = { "app.kubernetes.io/name" = "kube-network-policies" }
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "kube-network-policies" }
      }
      spec {
        dns_policy           = "ClusterFirst"
        host_network         = true
        node_selector        = { "kubernetes.io/os" = "linux" }
        service_account_name = kubernetes_service_account.main.metadata[0].name
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
          image = "registry.k8s.io/networking/kube-network-policies:v0.9.2"
          args = [
            "/bin/netpol",
            "--hostname-override=$(MY_NODE_NAME)",
            "--metrics-bind-address=:9080",
            "--nfqueue-id=98",
            "--v=2",
          ]
          volume_mount {
            name       = "nri-plugin"
            mount_path = "/var/run/nri"
          }
          volume_mount {
            name              = "netns"
            mount_path        = "/var/run/netns"
            mount_propagation = "HostToContainer"
          }
          resources {
            requests = { cpu = "1m", memory = "30Mi" }
            limits   = { memory = "100Mi" }
          }
          security_context {
            privileged = true
            capabilities {
              add = ["NET_ADMIN"]
            }
          }
          env {
            name = "MY_NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          port {
            name           = "metrics"
            container_port = 9080
            protocol       = "TCP"
          }
        }
        volume {
          name = "nri-plugin"
          host_path {
            path = "/var/run/nri"
          }
        }
        volume {
          name = "netns"
          host_path {
            path = "/var/run/netns"
          }
        }
      }
    }
  }
}
