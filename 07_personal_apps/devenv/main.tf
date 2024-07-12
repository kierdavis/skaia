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

variable "archive_secret_name" {
  type = string
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

module "image" {
  source         = "../../modules/container_image"
  repo_name      = "skaia-personal-devenv"
  repo_namespace = local.globals.docker_hub.namespace
  src            = "${path.module}/image"
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
          image = module.image.tag
          env {
            name  = "TZ"
            value = "Europe/London"
          }
          env_from {
            secret_ref {
              name = var.archive_secret_name
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
      }
    }
  }
}
