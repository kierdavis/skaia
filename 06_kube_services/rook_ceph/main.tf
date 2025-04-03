terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
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
  rook_version = "1.14.9"
  ceph_version = "18.2.2"

  globals = yamldecode(file("${path.module}/../../globals.yaml"))
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

locals {
  namespace = kubernetes_namespace.main.metadata[0].name
}

module "imperative_config" {
  source     = "./imperative_config"
  depends_on = [kubectl_manifest.cluster]
  namespace  = local.namespace
  rook_image = local.rook_image
}
