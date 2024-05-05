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

resource "kubernetes_manifest" "fs" {
  manifest = {
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephFilesystem"
    metadata = {
      name      = var.name
      namespace = var.cluster_namespace
    }
    spec = {
      metadataPool = {
        replicated = { size = 2 }
        parameters = {
          crush_rule = "skaia_gp0"
          pg_num_min = "1"
          bulk       = "0"
        }
      }
      dataPools = [{
        replicated = { size = 2 }
        parameters = {
          crush_rule = var.crush_rule
          pg_num_min = "1"
          bulk       = "1"
        }
      }]
      metadataServer = {
        activeCount       = 1 # Controls sharding, not redundancy.
        priorityClassName = "system-cluster-critical"
      }
    }
  }
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
    fsName                                                  = kubernetes_manifest.fs.object.metadata.name
    pool                                                    = "${kubernetes_manifest.fs.object.metadata.name}-data0"
    "csi.storage.k8s.io/provisioner-secret-name"            = "rook-csi-cephfs-provisioner"
    "csi.storage.k8s.io/provisioner-secret-namespace"       = var.cluster_namespace
    "csi.storage.k8s.io/controller-expand-secret-name"      = "rook-csi-cephfs-provisioner"
    "csi.storage.k8s.io/controller-expand-secret-namespace" = var.cluster_namespace
    "csi.storage.k8s.io/node-stage-secret-name"             = "rook-csi-cephfs-node"
    "csi.storage.k8s.io/node-stage-secret-namespace"        = var.cluster_namespace
  }
}
