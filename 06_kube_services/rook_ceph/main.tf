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

  # Use failureDomain = "host" because it's far more likely that a node will
  # crash or be placed under maintenance than that a disk will actually fail.
  # Note that if _any_ pg is unavailable because both of the OSDs it resides
  # on are down, the mds fail to start up (stay in "rejoin" state), causing
  # all filesystems to be inaccessible. Thanks, Ceph.

  meta_pool_spec = {
    replicated    = { size = 2 }
    failureDomain = "host"
    parameters = {
      pg_num = "2"
      bulk   = "0"
    }
  }

  data_classes = {
    gp0 = {
      pool_spec = {
        replicated    = { size = 2 }
        failureDomain = "host"
        parameters = {
          pg_num = "16"
          bulk   = "1"
        }
      }
    }
    media0 = {
      pool_spec = {
        replicated    = { size = 2 }
        failureDomain = "host"
        crushRoot     = "z-adw"
        parameters = {
          pg_num = "16"
          bulk   = "1"
        }
      }
    }
  }

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
