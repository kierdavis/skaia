terraform {
  backend "local" {
    path = "/net/skaia/tfstate/skaia/05_kube_essential.tfstate"
  }
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

provider "dockerhub" {
  username = local.globals.docker_hub.username
  password = local.globals.docker_hub.password
}

data "terraform_remote_state" "talos" {
  backend = "local"
  config = {
    path = "/net/skaia/tfstate/skaia/04_talos.tfstate"
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.talos.outputs.kubernetes.host
  cluster_ca_certificate = data.terraform_remote_state.talos.outputs.kubernetes.cluster_ca_certificate
  client_certificate     = data.terraform_remote_state.talos.outputs.kubernetes.client_certificate
  client_key             = data.terraform_remote_state.talos.outputs.kubernetes.client_key
}

resource "kubernetes_namespace" "system" {
  metadata {
    name = "system"
    labels = {
      "pod-security.kubernetes.io/audit"           = "privileged"
      "pod-security.kubernetes.io/audit-version"   = "latest"
      "pod-security.kubernetes.io/enforce"         = "privileged"
      "pod-security.kubernetes.io/enforce-version" = "latest"
      "pod-security.kubernetes.io/warn"            = "privileged"
      "pod-security.kubernetes.io/warn-version"    = "latest"
    }
  }
}
