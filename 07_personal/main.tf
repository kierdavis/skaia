terraform {
  backend "local" {
    path = "/net/skaia/tfstate/skaia/07_personal.tfstate"
  }
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    dockerhub = {
      source = "BarnabyShearer/dockerhub"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    postgresql = {
      source = "cyrilgdn/postgresql"
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

data "terraform_remote_state" "kube_services" {
  backend = "local"
  config = {
    path = "/net/skaia/tfstate/skaia/06_kube_services.tfstate"
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
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
  load_config_file       = false
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.talos.outputs.kubernetes.host
  cluster_ca_certificate = data.terraform_remote_state.talos.outputs.kubernetes.cluster_ca_certificate
  client_certificate     = data.terraform_remote_state.talos.outputs.kubernetes.client_certificate
  client_key             = data.terraform_remote_state.talos.outputs.kubernetes.client_key
}

provider "postgresql" {
  host     = module.postgresql.host
  username = module.postgresql.username
  password = module.postgresql.password
  sslmode  = module.postgresql.sslmode
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
  nix_cache           = module.nix_cache
}

module "ensouled_skin" {
  source                             = "./ensouled_skin"
  namespace                          = kubernetes_namespace.main.metadata[0].name
  cloudflare_account_id              = var.cloudflare_account_id
  cloudflare_tunnel_ingress_hostname = data.terraform_remote_state.kube_services.outputs.cloudflare_tunnel_ingress_hostname
  postgresql                         = module.postgresql
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
  projects_pvc_name      = module.storage.projects_pvc_name
  postgresql             = module.postgresql
  nix_cache              = module.nix_cache
}

module "jellyfin" {
  source             = "./jellyfin"
  namespace          = kubernetes_namespace.main.metadata[0].name
  media_pvc_name     = module.storage.media_pvc_name
  downloads_pvc_name = module.storage.downloads_pvc_name
}

module "karakeep" {
  source    = "./karakeep"
  namespace = kubernetes_namespace.main.metadata[0].name
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

module "postgresql" {
  source    = "./postgresql"
  namespace = kubernetes_namespace.main.metadata[0].name
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
  source    = "./storage"
  namespace = kubernetes_namespace.main.metadata[0].name
  backup    = module.backup_common
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

output "backup" {
  value = module.backup_common
}

output "hydra_ssh_public_key" {
  value = module.hydra.ssh_public_key
}
