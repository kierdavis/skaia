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

variable "pvc_name" {
  type = string
}

variable "mount_path" {
  type = string
}

variable "archive_secret_name" {
  type = string
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
              image = "docker.io/restic/restic@sha256:157243d77bc38be75a7b62b0c00453683251310eca414b9389ae3d49ea426c16"
              args = [
                "backup",
                "--exclude=lost+found",
                "--exclude=.nobackup",
                "--exclude=.Trash-*",
                "--host=generic",
                "--one-file-system",
                "--read-concurrency=4",
                "--tag=auto",
                var.mount_path,
              ]
              env_from {
                secret_ref {
                  name = var.archive_secret_name
                }
              }
              volume_mount {
                name       = "data"
                mount_path = var.mount_path
                read_only  = true
              }
            }
            volume {
              name = "data"
              persistent_volume_claim {
                claim_name = var.pvc_name
              }
            }
          }
        }
      }
    }
  }
}
