terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    tls = {
      source = "hashicorp/tls"
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

locals {
  globals = yamldecode(file("${path.module}/../../../globals.yaml"))
}

module "image" {
  source         = "../../../modules/stamp_image"
  repo_name      = "skaia-backup"
  repo_namespace = local.globals.docker_hub.username
  flake_output   = "./${path.module}/../../..#personal.backup.common.image"
}

output "image" {
  value = module.image.repo_tag
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

resource "tls_private_key" "ssh" {
  for_each  = toset(["client", "server"])
  algorithm = "ED25519"
}

resource "kubernetes_secret" "sidecar" {
  metadata {
    name      = "backup-sc"
    namespace = var.namespace
  }
  data = {
    ssh_host_ed25519_key = tls_private_key.ssh["server"].private_key_openssh
    authorized_keys      = tls_private_key.ssh["client"].public_key_openssh
  }
}

output "sidecar" {
  value = {
    secret_name        = kubernetes_secret.sidecar.metadata[0].name
    secret_mount_point = "/keys"
    port               = 2222
    requests           = { cpu = "1m", memory = "5Mi" }
    limits             = { memory = "500Mi" }
  }
}

resource "kubernetes_secret" "sidecar_client" {
  metadata {
    name      = "backup-sc-client"
    namespace = var.namespace
  }
  data = {
    id_ed25519  = tls_private_key.ssh["client"].private_key_openssh
    known_hosts = join(" ", ["*", tls_private_key.ssh["server"].public_key_openssh])
  }
}

output "sidecar_client_secret_name" {
  value = kubernetes_secret.sidecar_client.metadata[0].name
}
