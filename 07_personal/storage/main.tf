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

output "downloads_pvc_name" {
  value = kubernetes_persistent_volume_claim.downloads.metadata[0].name
}

output "media_pvc_name" {
  value = kubernetes_persistent_volume_claim.video.metadata[0].name
}

output "photography_pvc_name" {
  value = kubernetes_persistent_volume_claim.photography.metadata[0].name
}

output "projects_pvc_name" {
  value = kubernetes_persistent_volume_claim.projects.metadata[0].name
}

output "documents_pvc_name" {
  value = kubernetes_persistent_volume_claim.documents.metadata[0].name
}
