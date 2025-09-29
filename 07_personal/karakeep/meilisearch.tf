resource "random_password" "meilisearch" {
  length  = 20
  special = false
}

resource "kubernetes_secret" "meilisearch" {
  metadata {
    name      = "karakeep-meilisearch"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "karakeep-meilisearch"
      "app.kubernetes.io/component" = "meilisearch"
      "app.kubernetes.io/part-of"   = "karakeep"
    }
  }
  data = {
    MEILI_MASTER_KEY = random_password.meilisearch.result
  }
}

resource "kubernetes_stateful_set" "meilisearch" {
  wait_for_rollout = false
  metadata {
    name      = "karakeep-meilisearch"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "karakeep-meilisearch"
      "app.kubernetes.io/component" = "meilisearch"
      "app.kubernetes.io/part-of"   = "karakeep"
    }
  }
  spec {
    replicas     = 1
    service_name = "karakeep-meilisearch"
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "karakeep-meilisearch"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "karakeep-meilisearch"
          "app.kubernetes.io/component" = "meilisearch"
          "app.kubernetes.io/part-of"   = "karakeep"
        }
        annotations = {
          "confighash.skaia.cloud/secret" = nonsensitive(md5(jsonencode(kubernetes_secret.meilisearch.data)))
        }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        container {
          name  = "main"
          image = "docker.io/getmeili/meilisearch:v1.13.3"
          env {
            name  = "MEILI_NO_ANALYTICS"
            value = "true"
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.meilisearch.metadata[0].name
            }
          }
          volume_mount {
            name       = "state"
            mount_path = "/meili_data"
            read_only  = false
          }
          port {
            name           = "main"
            container_port = 7700
            protocol       = "TCP"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "state"
        labels = {
          "app.kubernetes.io/name"      = "karakeep-meilisearch"
          "app.kubernetes.io/component" = "meilisearch"
          "app.kubernetes.io/part-of"   = "karakeep"
        }
        annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "55 4 * * *" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "rbd-gp0"
        volume_mode        = "Filesystem"
        resources {
          requests = { storage = "1Gi" }
        }
      }
    }
  }
}

resource "kubernetes_service" "meilisearch" {
  metadata {
    name      = "karakeep-meilisearch"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "karakeep-meilisearch"
      "app.kubernetes.io/component" = "meilisearch"
      "app.kubernetes.io/part-of"   = "karakeep"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "karakeep-meilisearch"
    }
    port {
      name         = "main"
      port         = 7700
      protocol     = "TCP"
      app_protocol = "http"
      target_port  = "main"
    }
  }
}
