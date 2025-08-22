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

variable "media_pvc_name" {
  type = string
}

variable "downloads_pvc_name" {
  type = string
}

variable "projects_pvc_name" {
  type = string
}

variable "documents_pvc_name" {
  type = string
}

variable "archive_secret_name" {
  type = string
}

variable "nix_cache" {
  type = object({
    config_map_name = string
    secret_name     = string
    confighash      = string
  })
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

module "image" {
  source         = "../../modules/stamp_image"
  repo_name      = "skaia-personal-devenv"
  repo_namespace = local.globals.docker_hub.username
  flake_output   = "./${path.module}/../..#personal.devenv.image"
}

resource "kubernetes_deployment" "main" {
  wait_for_rollout = false
  metadata {
    name      = "devenv"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "devenv" }
  }
  spec {
    replicas = 1
    selector {
      match_labels = { "app.kubernetes.io/name" = "devenv" }
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "devenv" }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        container {
          name  = "main"
          image = module.image.repo_tag
          env {
            name  = "TZ"
            value = "Europe/London"
          }
          env_from {
            secret_ref {
              name = var.archive_secret_name
            }
          }
          env {
            name  = "B2_APPLICATION_KEY_ID"
            value = "$(B2_ACCOUNT_ID)"
          }
          env {
            name  = "B2_APPLICATION_KEY"
            value = "$(B2_ACCOUNT_KEY)"
          }
          dynamic "env" {
            for_each = toset(["BUCKET_NAME", "BUCKET_HOST", "BUCKET_REGION"])
            content {
              name = "NIX_CACHE_${env.key}"
              value_from {
                config_map_key_ref {
                  name     = var.nix_cache.config_map_name
                  key      = env.key
                  optional = true
                }
              }
            }
          }
          dynamic "env" {
            for_each = toset(["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"])
            content {
              name = "NIX_CACHE_${env.key}"
              value_from {
                secret_key_ref {
                  name     = var.nix_cache.secret_name
                  key      = env.key
                  optional = true
                }
              }
            }
          }
          volume_mount {
            name       = "media"
            mount_path = "/net/skaia/media"
          }
          volume_mount {
            name       = "downloads"
            mount_path = "/net/skaia/torrent-downloads"
          }
          volume_mount {
            name       = "projects"
            mount_path = "/net/skaia/projects"
          }
          volume_mount {
            name       = "documents"
            mount_path = "/net/skaia/documents"
          }
          resources {
            requests = { cpu = "1m", memory = "5Mi" }
            limits   = { memory = "6Gi" }
          }
          startup_probe {
            exec {
              command = ["test", "-e", "/ready/ready"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 1
            success_threshold     = 1
            failure_threshold     = 720
          }
        }
        volume {
          name = "media"
          persistent_volume_claim {
            claim_name = var.media_pvc_name
          }
        }
        volume {
          name = "downloads"
          persistent_volume_claim {
            claim_name = var.downloads_pvc_name
          }
        }
        volume {
          name = "projects"
          persistent_volume_claim {
            claim_name = var.projects_pvc_name
          }
        }
        volume {
          name = "documents"
          persistent_volume_claim {
            claim_name = var.documents_pvc_name
          }
        }
      }
    }
  }
}
