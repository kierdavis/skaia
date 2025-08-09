terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "schedule" {
  type = string
}

variable "sidecar_address" {
  type = string
}

variable "common" {
  type = object({
    image                      = string
    sidecar_client_secret_name = string
  })
}

resource "kubernetes_cron_job_v1" "main" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = var.name }
  }
  spec {
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 1
    schedule                      = var.schedule
    starting_deadline_seconds     = 6 * 60 * 60
    successful_jobs_history_limit = 1
    job_template {
      metadata {
        labels = { "app.kubernetes.io/name" = var.name }
      }
      spec {
        backoff_limit = 0
        template {
          metadata {
            labels = { "app.kubernetes.io/name" = var.name }
          }
          spec {
            restart_policy = "Never"
            container {
              name  = "main"
              image = var.common.image
              args  = ["sidecar-client", var.sidecar_address]
              volume_mount {
                name       = "keys"
                mount_path = "/keys"
                read_only  = true
              }
            }
            volume {
              name = "keys"
              secret {
                secret_name  = var.common.sidecar_client_secret_name
                default_mode = "0600"
              }
            }
          }
        }
      }
    }
  }
}
