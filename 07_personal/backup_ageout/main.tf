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

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
  labels  = { "app.kubernetes.io/name" = "backup-ageout" }
}

module "image" {
  source         = "../../modules/stamp_image"
  repo_name      = "skaia-backup-ageout"
  repo_namespace = local.globals.docker_hub.username
  flake          = "./${path.module}/../..#personal.backupAgeout.image"
}

resource "kubernetes_cron_job_v1" "main" {
  metadata {
    name      = "backup-ageout"
    namespace = var.namespace
    labels    = local.labels
  }
  spec {
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 1
    schedule                      = "0 3 * * *"
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
              args  = ["--force"]
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
