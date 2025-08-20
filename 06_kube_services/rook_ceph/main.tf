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
  rook_version = "1.17.7"
  ceph_version = "19.2.3-20250717"

  # Values that match the rook-version and ceph-version labels placed on
  # workloads by the operator.
  rook_version_label = "v${local.rook_version}"
  ceph_version_label = "${split("-", local.ceph_version)[0]}-0"

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
