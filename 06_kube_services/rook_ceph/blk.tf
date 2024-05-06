locals {
  blk_classes = toset(["gp0", "media0"])
}

resource "kubectl_manifest" "blk_meta_pool" {
  for_each   = local.blk_classes
  depends_on = [kubectl_manifest.cluster, kubernetes_job.imperative_config]
  yaml_body = yamlencode({
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephBlockPool"
    metadata = {
      name      = "blk-${each.key}-meta"
      namespace = local.namespace
    }
    spec = {
      replicated = { size = 2 }
      parameters = {
        crush_rule = "skaia_gp0"
        pg_num_min = "1"
        bulk       = "0"
      }
    }
  })
}

resource "kubectl_manifest" "blk_data_pool" {
  for_each   = local.blk_classes
  depends_on = [kubectl_manifest.cluster, kubernetes_job.imperative_config]
  yaml_body = yamlencode({
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephBlockPool"
    metadata = {
      name      = "blk-${each.key}-data"
      namespace = local.namespace
    }
    spec = {
      replicated = { size = 2 }
      parameters = {
        crush_rule = "skaia-${each.key}"
        pg_num_min = "4"
        bulk       = "1"
      }
    }
  })
}

resource "kubernetes_storage_class" "blk" {
  for_each = local.blk_classes
  metadata {
    name   = "blk-${each.key}"
    labels = { "skaia.cloud/type" = "rook-ceph-blk" }
  }
  storage_provisioner    = "rook-ceph.rbd.csi.ceph.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  parameters = {
    clusterID                                               = local.namespace
    pool                                                    = kubectl_manifest.blk_meta_pool[each.key].name
    dataPool                                                = kubectl_manifest.blk_data_pool[each.key].name
    "csi.storage.k8s.io/fstype"                             = "ext4"
    "csi.storage.k8s.io/provisioner-secret-name"            = "rook-csi-rbd-provisioner"
    "csi.storage.k8s.io/provisioner-secret-namespace"       = local.namespace
    "csi.storage.k8s.io/controller-expand-secret-name"      = "rook-csi-rbd-provisioner"
    "csi.storage.k8s.io/controller-expand-secret-namespace" = local.namespace
    "csi.storage.k8s.io/node-stage-secret-name"             = "rook-csi-rbd-node"
    "csi.storage.k8s.io/node-stage-secret-namespace"        = local.namespace
  }
}
