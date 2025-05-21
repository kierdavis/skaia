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

variable "b2_account_id" {
  type = string
}

variable "b2_account_key" {
  type      = string
  sensitive = true
  ephemeral = false # because it's persisted into a kubernetes_secret
}

variable "b2_archive_bucket" {
  type = string
}

variable "b2_archive_restic_password" {
  type      = string
  sensitive = true
  ephemeral = false # because it's persisted into a kubernetes_secret
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
