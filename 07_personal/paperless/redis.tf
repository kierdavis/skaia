resource "kubernetes_stateful_set" "redis" {
  wait_for_rollout = false
  metadata {
    name      = "paperless-redis"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "paperless-redis"
      "app.kubernetes.io/component" = "redis"
      "app.kubernetes.io/part-of"   = "paperless"
    }
  }
  spec {
    replicas     = 1
    service_name = "paperless-redis"
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "paperless-redis"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "paperless-redis"
          "app.kubernetes.io/component" = "redis"
          "app.kubernetes.io/part-of"   = "paperless"
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
          "app.kubernetes.io/name"      = "paperless-redis"
          "app.kubernetes.io/component" = "redis"
          "app.kubernetes.io/part-of"   = "paperless"
        }
        annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "25 4 * * *" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "rbd-documents0"
        volume_mode        = "Filesystem"
        resources {
          requests = { storage = "1Gi" }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "paperless-redis"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "paperless-redis"
      "app.kubernetes.io/component" = "redis"
      "app.kubernetes.io/part-of"   = "paperless"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "paperless-redis"
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
