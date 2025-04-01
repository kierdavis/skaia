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

output "downloads_pvc_name" {
  value = kubernetes_persistent_volume_claim.downloads.metadata[0].name
}

output "media_pvc_name" {
  value = kubernetes_persistent_volume_claim.video.metadata[0].name
}

output "projects_pvc_name" {
  value = kubernetes_persistent_volume_claim.projects.metadata[0].name
}

output "documents_pvc_name" {
  value = kubernetes_persistent_volume_claim.documents.metadata[0].name
}

output "archive_secret_name" {
  value = kubernetes_secret.archive.metadata[0].name
}
