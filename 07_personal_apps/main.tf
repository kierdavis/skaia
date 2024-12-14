terraform {
  required_providers {
    dockerhub = {
      source = "BarnabyShearer/dockerhub"
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
    path = "${path.module}/../04_talos/terraform.tfstate"
  }
}

provider "dockerhub" {
  username = local.globals.docker_hub.username
  password = local.globals.docker_hub.password
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

module "devenv" {
  source              = "./devenv"
  namespace           = kubernetes_namespace.main.metadata[0].name
  media_pvc_name      = module.storage.media_pvc_name
  downloads_pvc_name  = module.storage.downloads_pvc_name
  projects_pvc_name   = module.storage.projects_pvc_name
  documents_pvc_name  = module.storage.documents_pvc_name
  archive_secret_name = module.storage.archive_secret_name
}

module "git" {
  source              = "./git"
  namespace           = kubernetes_namespace.main.metadata[0].name
  archive_secret_name = module.storage.archive_secret_name
}

module "jellyfin" {
  source             = "./jellyfin"
  namespace          = kubernetes_namespace.main.metadata[0].name
  media_pvc_name     = module.storage.media_pvc_name
  downloads_pvc_name = module.storage.downloads_pvc_name
}

module "paperless" {
  source    = "./paperless"
  namespace = kubernetes_namespace.main.metadata[0].name
}

module "storage" {
  source    = "./storage"
  namespace = kubernetes_namespace.main.metadata[0].name
}

module "transcoding" {
  source             = "./transcoding"
  namespace          = kubernetes_namespace.main.metadata[0].name
  media_pvc_name     = module.storage.media_pvc_name
  downloads_pvc_name = module.storage.downloads_pvc_name
}

#module "vaultwarden" {
#  source    = "./vaultwarden"
#  namespace = kubernetes_namespace.main.metadata[0].name
#}
