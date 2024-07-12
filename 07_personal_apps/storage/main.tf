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
