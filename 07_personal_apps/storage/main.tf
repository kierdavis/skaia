terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

variable "namespace" {
  type = string
}

resource "kubernetes_persistent_volume_claim" "downloads" {
  metadata {
    name      = "torrent-downloads"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "fs-media0"
    resources {
      requests = { storage = "750Gi" }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "media" {
  metadata {
    name      = "media"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "fs-media0"
    resources {
      requests = { storage = "200Gi" }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "projects" {
  metadata {
    name      = "projects"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "fs-gp0"
    resources {
      requests = { storage = "100Gi" }
    }
  }
}

resource "kubernetes_secret" "archive" {
  metadata {
    name      = "archive"
    namespace = var.namespace
  }
  data = {
    B2_ACCOUNT_ID   = local.globals.b2.account_id
    B2_ACCOUNT_KEY  = local.globals.b2.account_key
    RESTIC_PASSWORD = local.globals.b2.archive.restic_password
  }
}

module "media_backup" {
  source              = "../restic_cron_job"
  name                = "media-backup"
  namespace           = var.namespace
  schedule            = "0 2 * * 2"
  pvc_name            = kubernetes_persistent_volume_claim.media.metadata[0].name
  mount_path          = "/net/skaia/media"
  archive_secret_name = kubernetes_secret.archive.metadata[0].name
}

module "projects_backup" {
  source              = "../restic_cron_job"
  name                = "projects-backup"
  namespace           = var.namespace
  schedule            = "0 2 * * *"
  pvc_name            = kubernetes_persistent_volume_claim.projects.metadata[0].name
  mount_path          = "/net/skaia/projects"
  archive_secret_name = kubernetes_secret.archive.metadata[0].name
}

output "downloads_pvc_name" {
  value = kubernetes_persistent_volume_claim.downloads.metadata[0].name
}

output "media_pvc_name" {
  value = kubernetes_persistent_volume_claim.media.metadata[0].name
}

output "projects_pvc_name" {
  value = kubernetes_persistent_volume_claim.projects.metadata[0].name
}

output "archive_secret_name" {
  value = kubernetes_secret.archive.metadata[0].name
}

#resource "kubernetes_job" "restic_init" {
#  metadata {
#    name = "restic-init"
#    namespace = var.namespace
#    labels = { "app.kubernetes.io/name" = "restic-init" }
#  }
#  spec {
#    backoff_limit = 0
#    template {
#      metadata {
#        labels = { "app.kubernetes.io/name" = "restic-init" }
#      }
#      spec {
#        restart_policy = "Never"
#        container {
#          name = "main"
#          image = "docker.io/restic/restic@sha256:157243d77bc38be75a7b62b0c00453683251310eca414b9389ae3d49ea426c16"
#          args = [
#            "init",
#            "--repo=b2:${local.globals.b2.archive.bucket}:/skaia/personal-1",
#          ]
#          env_from {
#            secret_ref {
#              name = kubernetes_secret.archive.metadata[0].name
#            }
#          }
#        }
#      }
#    }
#  }
#}
