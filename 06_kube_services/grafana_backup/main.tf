terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "grafana" {
  type = object({
    url = string
  })
}

variable "archive_secret_name" {
  type = string
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

module "image" {
  source         = "../../modules/stamp_image"
  repo_name      = "skaia-grafana-backup"
  repo_namespace = local.globals.docker_hub.username
  flake_output   = "./${path.module}/../..#kubeServices.grafanaBackup.image"
}

resource "grafana_service_account" "main" {
  name = "backup"
  role = "Viewer"
}

resource "grafana_service_account_token" "main" {
  name               = "main"
  service_account_id = grafana_service_account.main.id
}

resource "kubernetes_config_map" "main" {
  metadata {
    name      = "grafana-backup"
    namespace = "system"
    labels    = { "app.kubernetes.io/name" = "grafana-backup" }
  }
  data = {
    GRAFANA_URL         = var.grafana.url
    RESTIC_VIRTUAL_PATH = "/data/services/grafana/dashboards"
  }
}

resource "kubernetes_secret" "main" {
  metadata {
    name      = "grafana-backup"
    namespace = "system"
    labels    = { "app.kubernetes.io/name" = "grafana-backup" }
  }
  data = {
    GRAFANA_TOKEN = grafana_service_account_token.main.key
  }
}

resource "kubernetes_cron_job_v1" "main" {
  metadata {
    name      = "grafana-backup"
    namespace = "system"
    labels    = { "app.kubernetes.io/name" = "grafana-backup" }
  }
  spec {
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 1
    schedule                      = "0 2 * * 0"
    starting_deadline_seconds     = 6 * 60 * 60
    successful_jobs_history_limit = 1
    job_template {
      metadata {
        labels = { "app.kubernetes.io/name" = "grafana-backup" }
      }
      spec {
        backoff_limit = 0
        template {
          metadata {
            labels = { "app.kubernetes.io/name" = "grafana-backup" }
          }
          spec {
            restart_policy = "Never"
            container {
              name  = "main"
              image = module.image.repo_tag
              env_from {
                config_map_ref {
                  name = kubernetes_config_map.main.metadata[0].name
                }
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
