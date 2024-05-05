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

variable "fs_name" {
  type = string
}

variable "fs_data_pool_name" {
  type    = string
  default = "gp0"
}

resource "kubernetes_storage_class" "main" {
  metadata {
    name   = var.name
    labels = { "skaia.cloud/type" = "rook-ceph-fs" }
  }
  storage_provisioner    = "rook-ceph.cephfs.csi.ceph.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  parameters = {
    clusterID                                               = var.cluster_namespace
    fsName                                                  = var.fs_name
    pool                                                    = "${var.fs_name}-${var.fs_data_pool_name}"
    "csi.storage.k8s.io/provisioner-secret-name"            = "rook-csi-cephfs-provisioner"
    "csi.storage.k8s.io/provisioner-secret-namespace"       = var.cluster_namespace
    "csi.storage.k8s.io/controller-expand-secret-name"      = "rook-csi-cephfs-provisioner"
    "csi.storage.k8s.io/controller-expand-secret-namespace" = var.cluster_namespace
    "csi.storage.k8s.io/node-stage-secret-name"             = "rook-csi-cephfs-node"
    "csi.storage.k8s.io/node-stage-secret-namespace"        = var.cluster_namespace
  }
}
