terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
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
  metadata {
    name      = "kube-network-policies"
    namespace = "system"
    labels    = { "app.kubernetes.io/name" = "kube-network-policies" }
  }
  spec {
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "100%"
      }
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
        volume {
          name = "lib-modules"
          host_path {
            path = "/lib/modules"
          }
        }
        container {
          name  = "main"
          image = "registry.k8s.io/networking/kube-network-policies:v0.4.0"
          args = [
            "/bin/netpol",
            "--hostname-override=$(MY_NODE_NAME)",
            "--metrics-bind-address=:9080",
            "--v=1",
          ]
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
          volume_mount {
            name       = "lib-modules"
            mount_path = "/lib/modules"
            read_only  = true
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "main" {
  metadata {
    name      = "kube-network-policies"
    namespace = "system"
    labels    = { "app.kubernetes.io/name" = "kube-network-policies" }
  }
  spec {
    selector = { "app.kubernetes.io/name" = "kube-network-policies" }
    port {
      name         = "metrics"
      port         = 9080
      protocol     = "TCP"
      app_protocol = "http"
      target_port  = "metrics"
    }
  }
}

resource "kubectl_manifest" "service_monitor" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "kube-network-policies"
      namespace = "system"
      labels    = { "app.kubernetes.io/name" = "kube-network-policies" }
    }
    spec = {
      selector = {
        matchLabels = { "app.kubernetes.io/name" = "kube-network-policies" }
      }
      endpoints = [{
        port   = "metrics"
        scheme = "http"
      }]
      namespaceSelector = {
        matchNames = ["system"]
      }
    }
  })
}
