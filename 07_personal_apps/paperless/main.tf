terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "namespace" {
  type = string
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

module "image" {
  source         = "../../modules/container_image_v2"
  repo_name      = "skaia-paperless"
  repo_namespace = local.globals.docker_hub.username
  src            = "${path.module}/image.nix"
}

resource "kubernetes_stateful_set" "main" {
  wait_for_rollout = false
  metadata {
    name      = "paperless"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "paperless"
      "app.kubernetes.io/component" = "webapp"
      "app.kubernetes.io/part-of"   = "paperless"
    }
  }
  spec {
    replicas     = 1
    service_name = "paperless"
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "paperless"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "paperless"
          "app.kubernetes.io/component" = "webapp"
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
          image = module.image.name_and_tag
          env {
            # Seems like inotify doesn't work on cephfs.
            name  = "PAPERLESS_CONSUMER_POLLING"
            value = "3600" # seconds
          }
          env {
            name = "PAPERLESS_OCR_USER_ARGS"
            value = jsonencode({
              invalidate_digital_signatures = true
            })
          }
          env {
            name  = "PAPERLESS_REDIS"
            value = "redis://${kubernetes_service.redis.metadata[0].name}.${var.namespace}.svc:6379"
          }
          env {
            name  = "PAPERLESS_TIKA_ENABLED"
            value = "1"
          }
          env {
            name  = "PAPERLESS_TIKA_ENDPOINT"
            value = "http://${kubernetes_service.tika.metadata[0].name}.${var.namespace}.svc:9998"
          }
          env {
            name  = "PAPERLESS_TIKA_GOTENBERG_ENDPOINT"
            value = "http://${kubernetes_service.gotenberg.metadata[0].name}.${var.namespace}.svc:3000"
          }
          env {
            name  = "PAPERLESS_TIME_ZONE"
            value = "Europe/London"
          }
          env {
            name  = "USERMAP_GID"
            value = local.globals.personal_uid
          }
          env {
            name  = "USERMAP_UID"
            value = local.globals.personal_uid
          }
          port {
            name           = "ui"
            container_port = 8000
            protocol       = "TCP"
          }
          readiness_probe {
            failure_threshold     = 3
            initial_delay_seconds = 5
            period_seconds        = 5
            success_threshold     = 1
            timeout_seconds       = 1
            http_get {
              path = "/"
              port = "ui"
            }
          }
          resources {
            requests = {
              cpu    = "20m"
              memory = "1Gi"
            }
            limits = {
              memory = "2Gi"
            }
          }
          volume_mount {
            name       = "database"
            mount_path = "/usr/src/paperless/data"
            read_only  = false
          }
          volume_mount {
            name       = "media"
            mount_path = "/usr/src/paperless/media"
            read_only  = false
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "database"
        labels = {
          "app.kubernetes.io/name"      = "paperless"
          "app.kubernetes.io/component" = "webapp"
          "app.kubernetes.io/part-of"   = "paperless"
        }
        annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "0 4 * * *" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "rbd-documents0"
        volume_mode        = "Filesystem"
        resources {
          requests = { storage = "2Gi" }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "media"
        labels = {
          "app.kubernetes.io/name"      = "paperless"
          "app.kubernetes.io/component" = "webapp"
          "app.kubernetes.io/part-of"   = "paperless"
        }
        annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "10 4 * * *" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "rbd-documents0"
        volume_mode        = "Filesystem"
        resources {
          requests = { storage = "20Gi" }
        }
      }
    }
  }
}

resource "kubernetes_service" "main" {
  metadata {
    name      = "paperless"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "paperless"
      "app.kubernetes.io/component" = "webapp"
      "app.kubernetes.io/part-of"   = "paperless"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "paperless"
    }
    port {
      name         = "ui"
      port         = 80
      protocol     = "TCP"
      app_protocol = "http"
      target_port  = "ui"
    }
  }
}
