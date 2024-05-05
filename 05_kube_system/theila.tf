resource "kubernetes_manifest" "theila_service_account" {
  manifest = {
    apiVersion = "talos.dev/v1alpha1"
    kind       = "ServiceAccount"
    metadata = {
      name      = "theila"
      namespace = kubernetes_namespace.system.metadata[0].name
      labels    = { "app.kubernetes.io/name" = "theila" }
    }
    spec = {
      roles = ["os:admin"]
    }
  }
}

# TODO: resources
resource "kubernetes_deployment" "theila" {
  metadata {
    name      = "theila"
    namespace = kubernetes_namespace.system.metadata[0].name
    labels    = { "app.kubernetes.io/name" = "theila" }
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
      match_labels = { "app.kubernetes.io/name" = "theila" }
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "theila" }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 1
        container {
          name  = "main"
          image = "ghcr.io/siderolabs/theila"
          args  = ["--address", "0.0.0.0"]
          env {
            name  = "TALOSCONFIG"
            value = "/var/run/secrets/talos.dev/config"
          }
          volume_mount {
            name       = "talos-service-account"
            mount_path = "/var/run/secrets/talos.dev"
          }
          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }
        }
        volume {
          name = "talos-service-account"
          secret {
            secret_name = kubernetes_manifest.theila_service_account.object.metadata.name
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
        dynamic "host_aliases" {
          for_each = data.terraform_remote_state.talos.outputs.node_endpoints
          content {
            ip        = host_aliases.value
            hostnames = ["kubeapi.skaia.cloud"]
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "theila" {
  metadata {
    name      = "theila"
    namespace = kubernetes_namespace.system.metadata[0].name
    labels    = { "app.kubernetes.io/name" = "theila" }
  }
  spec {
    ip_family_policy = "PreferDualStack"
    selector         = { "app.kubernetes.io/name" = "theila" }
    port {
      name        = "http"
      port        = 80
      protocol    = "TCP"
      target_port = "http"
    }
  }
}
