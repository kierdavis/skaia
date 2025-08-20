terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    http = {
      source = "hashicorp/http"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "grafana" {
  type = object({
    url      = string
    username = string
    password = string
  })
}

locals {
  # Choose from https://github.com/rook/rook/tags
  rook_version = "1.17.7"
  # Choose from https://quay.io/repository/ceph/ceph?tab=tags
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
