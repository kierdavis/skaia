resource "kubernetes_deployment" "tika" {
  wait_for_rollout = false
  metadata {
    name      = "paperless-ngx-tika"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "paperless-ngx-tika"
      "app.kubernetes.io/component" = "tika"
      "app.kubernetes.io/part-of"   = "paperless-ngx"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "paperless-ngx-tika"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "paperless-ngx-tika"
          "app.kubernetes.io/component" = "tika"
          "app.kubernetes.io/part-of"   = "paperless-ngx"
        }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        container {
          name  = "main"
          image = "docker.io/apache/tika@sha256:2be134745fcb59826c54041489946c66218b948ea0c0be3a37cb7919ecc845ba"
          port {
            name           = "main"
            container_port = 9998
            protocol       = "TCP"
          }
          resources {
            requests = {
              cpu    = "5m"
              memory = "250Mi"
            }
            limits = {
              memory = "500Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "tika" {
  metadata {
    name      = "paperless-ngx-tika"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "paperless-ngx-tika"
      "app.kubernetes.io/component" = "tika"
      "app.kubernetes.io/part-of"   = "paperless-ngx"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "paperless-ngx-tika"
    }
    port {
      name         = "main"
      port         = 9998
      protocol     = "TCP"
      app_protocol = "http"
      target_port  = "main"
    }
  }
}
