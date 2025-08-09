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

resource "kubernetes_secret" "archive" {
  metadata {
    name      = "archive"
    namespace = var.namespace
  }
  data = {
    B2_ACCOUNT_ID     = var.b2_account_id
    B2_ACCOUNT_KEY    = var.b2_account_key
    RESTIC_REPOSITORY = "b2:${var.b2_archive_bucket}:personal-restic"
    RESTIC_PASSWORD   = var.b2_archive_restic_password
  }
}

output "archive_secret_name" {
  value = kubernetes_secret.archive.metadata[0].name
}
