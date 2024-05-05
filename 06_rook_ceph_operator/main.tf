terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

locals {
  version = "1.14.3"
}

data "terraform_remote_state" "talos" {
  backend = "local"
  config = {
    path = "${path.module}/../04_talos/terraform.tfstate"
  }
}

provider "kubernetes" {
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

resource "kubernetes_namespace" "main" {
  metadata {
    name = "rook-ceph"
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

resource "helm_release" "main" {
  name       = "rook-ceph"
  chart      = "rook-ceph"
  repository = "https://charts.rook.io/release"
  version    = local.version
  namespace  = kubernetes_namespace.main.metadata[0].name
  values = [yamlencode({
    csi = {
      clusterName         = "skaia"
      provisionerReplicas = 1
      serviceMonitor = {
        enabled = false # TODO
      }
    }
    monitoring = {
      enabled = false # TODO
    }
  })]
}

data "kubernetes_resource" "deployment" {
  api_version = "apps/v1"
  kind        = "Deployment"
  metadata {
    name      = "rook-ceph-operator"
    namespace = kubernetes_namespace.main.metadata[0].name
  }
  depends_on = [helm_release.main]
}

output "namespace" {
  value = kubernetes_namespace.main.metadata[0].name
}

output "image" {
  value = data.kubernetes_resource.deployment.object.spec.template.spec.containers[0].image
}
