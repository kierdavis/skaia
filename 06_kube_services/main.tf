terraform {
  backend "local" {
    path = "/net/skaia/tfstate/skaia/06_kube_services.tfstate"
  }
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
    path = "/net/skaia/tfstate/skaia/04_talos.tfstate"
  }
}

provider "dockerhub" {
  username = local.globals.docker_hub.username
  password = var.docker_hub_password
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

module "coredns" {
  source = "./coredns"
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

module "prometheus" {
  source         = "./prometheus"
  depends_on     = [module.rook_ceph]
  node_endpoints = data.terraform_remote_state.talos.outputs.node_endpoints
  etcd_ca_cert   = data.terraform_remote_state.talos.outputs.etcd_ca_cert
  etcd_ca_key    = data.terraform_remote_state.talos.outputs.etcd_ca_key
}

module "rook_ceph" {
  source     = "./rook_ceph"
  depends_on = [module.csi_addons]
}
