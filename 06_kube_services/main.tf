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

provider "kubernetes" {
  host                   = data.terraform_remote_state.talos.outputs.kubernetes.host
  cluster_ca_certificate = data.terraform_remote_state.talos.outputs.kubernetes.cluster_ca_certificate
  client_certificate     = data.terraform_remote_state.talos.outputs.kubernetes.client_certificate
  client_key             = data.terraform_remote_state.talos.outputs.kubernetes.client_key
}

provider "kubectl" {
  host                   = data.terraform_remote_state.talos.outputs.kubernetes.host
  cluster_ca_certificate = data.terraform_remote_state.talos.outputs.kubernetes.cluster_ca_certificate
  client_certificate     = data.terraform_remote_state.talos.outputs.kubernetes.client_certificate
  client_key             = data.terraform_remote_state.talos.outputs.kubernetes.client_key
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.talos.outputs.kubernetes.host
    cluster_ca_certificate = data.terraform_remote_state.talos.outputs.kubernetes.cluster_ca_certificate
    client_certificate     = data.terraform_remote_state.talos.outputs.kubernetes.client_certificate
    client_key             = data.terraform_remote_state.talos.outputs.kubernetes.client_key
  }
}

module "generic_device_plugin" {
  source = "./generic_device_plugin"
}

module "prometheus" {
  depends_on = [module.rook_ceph]
  source     = "./prometheus"
}

module "rook_ceph" {
  source = "./rook_ceph"
}

module "stash" {
  source = "./stash"
}
