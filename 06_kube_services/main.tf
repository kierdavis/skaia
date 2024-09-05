terraform {
  required_providers {
    dockerhub = {
      source = "BarnabyShearer/dockerhub"
    }
    helm = {
      source = "hashicorp/helm"
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
    tls = {
      source = "hashicorp/tls"
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

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.talos.outputs.kubernetes.host
    cluster_ca_certificate = data.terraform_remote_state.talos.outputs.kubernetes.cluster_ca_certificate
    client_certificate     = data.terraform_remote_state.talos.outputs.kubernetes.client_certificate
    client_key             = data.terraform_remote_state.talos.outputs.kubernetes.client_key
  }
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

provider "postgresql" {
  host     = module.postgresql.provider_config.host
  username = module.postgresql.provider_config.username
  password = module.postgresql.provider_config.password
  sslmode  = module.postgresql.provider_config.sslmode
}

module "csi_addons" {
  source = "./csi_addons"
}

module "generic_device_plugin" {
  source = "./generic_device_plugin"
}

module "kube_network_policies" {
  source     = "./kube_network_policies"
  depends_on = [module.prometheus]
}

module "postgresql" {
  source     = "./postgresql"
  depends_on = [module.rook_ceph]
}

module "prometheus" {
  source     = "./prometheus"
  depends_on = [module.rook_ceph]
}

module "rook_ceph" {
  source     = "./rook_ceph"
  depends_on = [module.csi_addons]
}
