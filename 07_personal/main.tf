terraform {
  backend "local" {
    path = "/net/skaia/tfstate/skaia/07_personal.tfstate"
  }
  required_providers {
    dockerhub = {
      source = "BarnabyShearer/dockerhub"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

locals {
  globals = yamldecode(file("${path.module}/../globals.yaml"))
}

data "terraform_remote_state" "talos" {
  backend = "local"
  config = {
    path = "/net/skaia/tfstate/skaia/04_talos.tfstate"
  }
}

provider "dockerhub" {
  username = local.globals.docker_hub.username
  password = var.docker_hub_password
}

provider "kubectl" {
  host                   = data.terraform_remote_state.talos.outputs.kubernetes.host
  cluster_ca_certificate = data.terraform_remote_state.talos.outputs.kubernetes.cluster_ca_certificate
  client_certificate     = data.terraform_remote_state.talos.outputs.kubernetes.client_certificate
  client_key             = data.terraform_remote_state.talos.outputs.kubernetes.client_key
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.talos.outputs.kubernetes.host
  cluster_ca_certificate = data.terraform_remote_state.talos.outputs.kubernetes.cluster_ca_certificate
  client_certificate     = data.terraform_remote_state.talos.outputs.kubernetes.client_certificate
  client_key             = data.terraform_remote_state.talos.outputs.kubernetes.client_key
}

resource "kubernetes_namespace" "main" {
  metadata {
    name = "personal"
    labels = {
      # Need privileged due to transmission's use of CAP_NET_ADMIN and /dev/net/tun
      "pod-security.kubernetes.io/audit"           = "privileged"
      "pod-security.kubernetes.io/audit-version"   = "latest"
      "pod-security.kubernetes.io/enforce"         = "privileged"
      "pod-security.kubernetes.io/enforce-version" = "latest"
      "pod-security.kubernetes.io/warn"            = "privileged"
      "pod-security.kubernetes.io/warn-version"    = "latest"
    }
  }
}

module "backup_ageout" {
  source              = "./backup_ageout"
  namespace           = kubernetes_namespace.main.metadata[0].name
  archive_secret_name = module.backup_common.archive_secret_name
}

module "backup_common" {
  source                     = "./backup/common"
  namespace                  = kubernetes_namespace.main.metadata[0].name
  b2_account_id              = var.b2_account_id
  b2_account_key             = var.b2_account_key
  b2_archive_bucket          = var.b2_archive_bucket
  b2_archive_restic_password = var.b2_archive_restic_password
}

module "devenv" {
  source              = "./devenv"
  namespace           = kubernetes_namespace.main.metadata[0].name
  media_pvc_name      = module.storage.media_pvc_name
  downloads_pvc_name  = module.storage.downloads_pvc_name
  projects_pvc_name   = module.storage.projects_pvc_name
  documents_pvc_name  = module.storage.documents_pvc_name
  archive_secret_name = module.backup_common.archive_secret_name
}

module "git" {
  source                     = "./git"
  namespace                  = kubernetes_namespace.main.metadata[0].name
  authorized_ssh_public_keys = setunion(var.authorized_ssh_public_keys, toset([module.hydra.ssh_public_key]))
  backup                     = module.backup_common
}

module "hydra" {
  source                 = "./hydra"
  namespace              = kubernetes_namespace.main.metadata[0].name
  nix_signing_secret_key = var.hydra_nix_signing_secret_key
  postgres_password      = var.hydra_postgres_password
  nix_cache              = module.nix_cache
}

module "jellyfin" {
  source             = "./jellyfin"
  namespace          = kubernetes_namespace.main.metadata[0].name
  media_pvc_name     = module.storage.media_pvc_name
  downloads_pvc_name = module.storage.downloads_pvc_name
}

module "nix_cache" {
  source    = "./nix_cache"
  namespace = kubernetes_namespace.main.metadata[0].name
}

module "paperless" {
  source    = "./paperless"
  namespace = kubernetes_namespace.main.metadata[0].name
  backup    = module.backup_common
}

module "refern_backup" {
  source                          = "./refern_backup"
  namespace                       = kubernetes_namespace.main.metadata[0].name
  archive_secret_name             = module.backup_common.archive_secret_name
  refern_email                    = var.refern_email
  refern_identity_toolkit_api_key = var.refern_identity_toolkit_api_key
  refern_password                 = var.refern_password
}

module "storage" {
  source              = "./storage"
  namespace           = kubernetes_namespace.main.metadata[0].name
  archive_secret_name = module.backup_common.archive_secret_name
}

module "todoist_automation" {
  source              = "./todoist_automation"
  namespace           = kubernetes_namespace.main.metadata[0].name
  archive_secret_name = module.backup_common.archive_secret_name
  todoist_email       = var.todoist_email
  todoist_api_token   = var.todoist_api_token
}

module "transcoding" {
  source             = "./transcoding"
  namespace          = kubernetes_namespace.main.metadata[0].name
  media_pvc_name     = module.storage.media_pvc_name
  downloads_pvc_name = module.storage.downloads_pvc_name
}

module "valheim_common" {
  source = "./valheim/common"
}

#module "valheim_foo" {
#  source          = "./valheim/instance"
#  namespace       = kubernetes_namespace.main.metadata[0].name
#  instance_name   = "foo"
#  server_name     = "my server name"
#  server_password = "super secret"
#  common          = module.valheim_common
#}

#module "vaultwarden" {
#  source    = "./vaultwarden"
#  namespace = kubernetes_namespace.main.metadata[0].name
#}

output "downloads_pvc_name" {
  value = module.storage.downloads_pvc_name
}

output "archive_secret_name" {
  value = module.backup_common.archive_secret_name
}

output "hydra_ssh_public_key" {
  value = module.hydra.ssh_public_key
}
