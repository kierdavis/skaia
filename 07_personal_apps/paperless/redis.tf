resource "kubernetes_stateful_set" "redis" {
  wait_for_rollout = false
  metadata {
    name      = "paperless-ngx-redis"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "paperless-ngx-redis"
      "app.kubernetes.io/component" = "redis"
      "app.kubernetes.io/part-of"   = "paperless-ngx"
    }
  }
  spec {
    replicas     = 1
    service_name = "paperless-ngx-redis"
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "paperless-ngx-redis"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "paperless-ngx-redis"
          "app.kubernetes.io/component" = "redis"
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
          image = "docker.io/library/redis@sha256:fb534a36ac2034a6374933467d971fbcbfa5d213805507f560d564851a720355"
          port {
            name           = "main"
            container_port = 6379
            protocol       = "TCP"
          }
          resources {
            requests = {
              cpu    = "2m"
              memory = "5Mi"
            }
            limits = {
              memory = "20Mi"
            }
          }
          volume_mount {
            name       = "state"
            mount_path = "/data"
            read_only  = false
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "state"
        labels = {
          "app.kubernetes.io/name"      = "paperless-ngx-redis"
          "app.kubernetes.io/component" = "redis"
          "app.kubernetes.io/part-of"   = "paperless-ngx"
        }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "blk-gp0"
        resources {
          requests = { storage = "1Gi" }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "paperless-ngx-redis"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "paperless-ngx-redis"
      "app.kubernetes.io/component" = "redis"
      "app.kubernetes.io/part-of"   = "paperless-ngx"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "paperless-ngx-redis"
    }
    port {
      name         = "main"
      port         = 6379
      protocol     = "TCP"
      app_protocol = "redis"
      target_port  = "main"
    }
  }
}
