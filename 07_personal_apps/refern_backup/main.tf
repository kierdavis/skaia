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
  labels  = { "app.kubernetes.io/name" = "refern-backup" }

  refern_email = "redacted@example.net"
}

module "image" {
  source         = "../../modules/container_image_v2"
  repo_name      = "skaia-refern-backup"
  repo_namespace = local.globals.docker_hub.namespace
  src            = "${path.module}/image.nix"
}

resource "kubernetes_config_map" "main" {
  metadata {
    name      = "refern-backup"
    namespace = var.namespace
    labels    = local.labels
  }
  data = {
    REFERN_EMAIL        = local.refern_email
    RESTIC_REPO         = "b2:${local.globals.b2.archive.bucket}:personal-restic"
    RESTIC_VIRTUAL_PATH = "/data/accounts/refern/${local.refern_email}"
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
    REFERN_IDENTITY_TOOLKIT_API_KEY = "REDACTED"
    REFERN_PASSWORD                 = "REDACTED"
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
