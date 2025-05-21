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

variable "archive_bucket" {
  type = string
}

variable "archive_secret_name" {
  type = string
}

variable "refern_email" {
  type = string
}

variable "refern_identity_toolkit_api_key" {
  type      = string
  sensitive = true
  ephemeral = false # because it's persisted into a kubernetes_secret
}

variable "refern_password" {
  type      = string
  sensitive = true
  ephemeral = false # because it's persisted into a kubernetes_secret
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
  labels  = { "app.kubernetes.io/name" = "refern-backup" }
}

module "image" {
  source         = "../../modules/container_image_v2"
  repo_name      = "skaia-refern-backup"
  repo_namespace = local.globals.docker_hub.username
  src            = "${path.module}/image.nix"
}

resource "kubernetes_config_map" "main" {
  metadata {
    name      = "refern-backup"
    namespace = var.namespace
    labels    = local.labels
  }
  data = {
    REFERN_EMAIL        = var.refern_email
    RESTIC_REPO         = "b2:${var.archive_bucket}:personal-restic"
    RESTIC_VIRTUAL_PATH = "/data/accounts/refern/${var.refern_email}"
    TMPDIR              = "/tmp"
  }
}

resource "kubernetes_secret" "main" {
  metadata {
    name      = "refern-backup"
    namespace = var.namespace
    labels    = local.labels
  }
  data = {
    REFERN_IDENTITY_TOOLKIT_API_KEY = var.refern_identity_toolkit_api_key
    REFERN_PASSWORD                 = var.refern_password
  }
}

resource "kubernetes_cron_job_v1" "main" {
  metadata {
    name      = "refern-backup"
    namespace = var.namespace
    labels    = local.labels
  }
  spec {
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 1
    schedule                      = "0 2 * * 1"
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
              image = module.image.name_and_tag
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
              volume_mount {
                name       = "downloads"
                mount_path = kubernetes_config_map.main.data.TMPDIR
              }
              volume_mount {
                name       = "staging"
                mount_path = kubernetes_config_map.main.data.RESTIC_VIRTUAL_PATH
              }
            }
            volume {
              name = "downloads"
              ephemeral {
                volume_claim_template {
                  metadata {
                    labels = local.labels
                  }
                  spec {
                    access_modes       = ["ReadWriteOnce"]
                    storage_class_name = "rbd-scratch0"
                    volume_mode        = "Filesystem"
                    resources {
                      requests = { storage = "10Gi" }
                    }
                  }
                }
              }
            }
            volume {
              name = "staging"
              ephemeral {
                volume_claim_template {
                  metadata {
                    labels = local.labels
                  }
                  spec {
                    access_modes       = ["ReadWriteOnce"]
                    storage_class_name = "rbd-scratch0"
                    volume_mode        = "Filesystem"
                    resources {
                      requests = { storage = "50Gi" }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
