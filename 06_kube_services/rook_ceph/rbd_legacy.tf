resource "kubectl_manifest" "rbd_metadata_pool_legacy" {
  for_each   = toset(["gp0"])
  depends_on = [kubectl_manifest.cluster, kubernetes_job.imperative_config]
  yaml_body = yamlencode({
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephBlockPool"
    metadata = {
      name      = "blk-${each.key}-meta"
      namespace = local.namespace
    }
    spec = {
      replicated    = { size = 2 }
      failureDomain = "host"
      parameters = {
        pg_num = "2"
        bulk   = "0"
      }
    }
  })
}

resource "kubectl_manifest" "rbd_data_pool_legacy" {
  for_each   = toset(["gp0"])
  depends_on = [kubectl_manifest.cluster, kubernetes_job.imperative_config]
  yaml_body = yamlencode({
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephBlockPool"
    metadata = {
      name      = "blk-${each.key}-data"
      namespace = local.namespace
    }
    spec = merge({
      replicated    = { size = 2 }
      failureDomain = "host"
      parameters = {
        pg_num = "16"
        bulk   = "1"
      }
    }, each.key == "media0" ? { crushRoot = "z-adw" } : {})
  })
}

resource "kubernetes_storage_class" "rbd_legacy" {
  for_each = toset(["gp0"])
  metadata {
    name   = "blk-${each.key}"
    labels = { "skaia.cloud/type" = "rbd" }
  }
  storage_provisioner    = "rook-ceph.rbd.csi.ceph.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  parameters = {
    clusterID                                               = local.namespace
    pool                                                    = kubectl_manifest.rbd_metadata_pool_legacy[each.key].name
    dataPool                                                = kubectl_manifest.rbd_data_pool_legacy[each.key].name
    "csi.storage.k8s.io/fstype"                             = "ext4"
    "csi.storage.k8s.io/provisioner-secret-name"            = "rook-csi-rbd-provisioner"
    "csi.storage.k8s.io/provisioner-secret-namespace"       = local.namespace
    "csi.storage.k8s.io/controller-expand-secret-name"      = "rook-csi-rbd-provisioner"
    "csi.storage.k8s.io/controller-expand-secret-namespace" = local.namespace
    "csi.storage.k8s.io/node-stage-secret-name"             = "rook-csi-rbd-node"
    "csi.storage.k8s.io/node-stage-secret-namespace"        = local.namespace
  }
}
