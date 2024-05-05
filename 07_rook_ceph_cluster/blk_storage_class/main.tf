terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "name" {
  type = string
}

variable "cluster_namespace" {
  type = string
}

variable "crush_rule" {
  type    = string
  default = "skaia_gp0"
}

resource "kubernetes_manifest" "meta_pool" {
  manifest = {
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephBlockPool"
    metadata = {
      name      = "${var.name}-meta"
      namespace = var.cluster_namespace
    }
    spec = {
      replicated = { size = 2 }
      parameters = {
        crush_rule = "skaia_gp0"
        pg_num_min = "1"
        bulk       = "0"
      }
    }
  }
}

resource "kubernetes_manifest" "data_pool" {
  manifest = {
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephBlockPool"
    metadata = {
      name      = "${var.name}-data"
      namespace = var.cluster_namespace
    }
    spec = {
      replicated = { size = 2 }
      parameters = {
        crush_rule = var.crush_rule
        pg_num_min = "1"
        bulk       = "1"
      }
    }
  }
}

resource "kubernetes_storage_class" "main" {
  metadata {
    name   = var.name
    labels = { "skaia.cloud/type" = "rook-ceph-blk" }
  }
  storage_provisioner    = "rook-ceph.rbd.csi.ceph.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  parameters = {
    clusterID                                               = var.cluster_namespace
    pool                                                    = kubernetes_manifest.meta_pool.object.metadata.name
    dataPool                                                = kubernetes_manifest.data_pool.object.metadata.name
    "csi.storage.k8s.io/fstype"                             = "ext4"
    "csi.storage.k8s.io/provisioner-secret-name"            = "rook-csi-rbd-provisioner"
    "csi.storage.k8s.io/provisioner-secret-namespace"       = var.cluster_namespace
    "csi.storage.k8s.io/controller-expand-secret-name"      = "rook-csi-rbd-provisioner"
    "csi.storage.k8s.io/controller-expand-secret-namespace" = var.cluster_namespace
    "csi.storage.k8s.io/node-stage-secret-name"             = "rook-csi-rbd-node"
    "csi.storage.k8s.io/node-stage-secret-namespace"        = var.cluster_namespace
  }
}
