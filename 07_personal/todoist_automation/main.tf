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

variable "archive_secret_name" {
  type = string
}

variable "todoist_email" {
  type = string
}

variable "todoist_api_token" {
  type      = string
  sensitive = true
  ephemeral = false
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
  labels  = { "app.kubernetes.io/name" = "refern-backup" }
}

module "image" {
  source         = "../../modules/stamp_image"
  repo_name      = "skaia-todoist-automation"
  repo_namespace = local.globals.docker_hub.username
  flake          = "path:${path.module}/../..#personal.todoistAutomation.image"
}

resource "kubernetes_secret" "main" {
  metadata {
    name      = "todoist-automation"
    namespace = var.namespace
    labels    = local.labels
  }
  data = {
    TODOIST_API_TOKEN = var.todoist_api_token
  }
}

resource "kubernetes_cron_job_v1" "main" {
  metadata {
    name      = "todoist-automation"
    namespace = var.namespace
    labels    = local.labels
  }
  spec {
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 1
    schedule                      = "2 0 * * *"
    starting_deadline_seconds     = 6 * 60 * 60
    successful_jobs_history_limit = 1
    job_template {
      metadata {
        labels = local.labels
      }
      spec {
        backoff_limit = 0
        template {
          metadata {
            labels = local.labels
          }
          spec {
            restart_policy = "Never"
            container {
              name  = "main"
              image = module.image.repo_tag
              env {
                name  = "RESTIC_VIRTUAL_PATH"
                value = "/data/accounts/todoist/${var.todoist_email}"
              }
              env_from {
                secret_ref {
                  name = kubernetes_secret.main.metadata[0].name
                }
              }
              env_from {
                secret_ref {
                  name = var.archive_secret_name
                }
              }
            }
          }
        }
      }
    }
  }
}
