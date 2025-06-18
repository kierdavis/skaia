locals {
  rbd_storage_classes = {
    documents0 = {
      data_pool_spec = {
        replicated    = { size = 2 }
        failureDomain = "host"
        parameters = {
          pg_num = "2"
          bulk   = "1"
        }
      }
    }
    gameservers0 = {
      data_pool_spec = {
        replicated    = { size = 2 }
        failureDomain = "host"
        parameters = {
          pg_num = "2"
          bulk   = "1"
        }
      }
    }
    monitoring0 = {
      data_pool_spec = {
        replicated    = { size = 2 }
        failureDomain = "host"
        parameters = {
          pg_num = "2"
          bulk   = "1"
        }
      }
    }
    rosebud0 = {
      data_pool_spec = {
        replicated    = { size = 2 }
        failureDomain = "host"
        parameters = {
          pg_num = "8"
          bulk   = "1"
        }
      }
    }
    scratch0 = {
      data_pool_spec = {
        replicated    = { size = 2 }
        failureDomain = "host"
        parameters = {
          pg_num = "2"
          bulk   = "1"
        }
      }
    }
    video0 = {
      data_pool_spec = {
        replicated    = { size = 2 }
        failureDomain = "host"
        crushRoot     = "z-adw"
        parameters = {
          pg_num = "2"
          bulk   = "1"
        }
      }
    }
  }
}

resource "kubectl_manifest" "rbd_metadata_pool" {
  depends_on = [kubectl_manifest.cluster, module.imperative_config]
  yaml_body = yamlencode({
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephBlockPool"
    metadata = {
      name      = "rbd-metadata"
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

resource "kubectl_manifest" "rbd_data_pool" {
  for_each   = local.rbd_storage_classes
  depends_on = [kubectl_manifest.cluster, module.imperative_config]
  yaml_body = yamlencode({
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephBlockPool"
    metadata = {
      name      = "rbd-${each.key}"
      namespace = local.namespace
    }
    spec = each.value.data_pool_spec
  })
}

resource "kubernetes_storage_class" "rbd" {
  for_each = local.rbd_storage_classes
  metadata {
    name   = "rbd-${each.key}"
    labels = { "skaia.cloud/type" = "rbd" }
  }
  storage_provisioner    = "rook-ceph.rbd.csi.ceph.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  parameters = {
    clusterID                                               = local.namespace
    pool                                                    = kubectl_manifest.rbd_metadata_pool.name
    dataPool                                                = kubectl_manifest.rbd_data_pool[each.key].name
    "csi.storage.k8s.io/fstype"                             = "ext4"
    "csi.storage.k8s.io/provisioner-secret-name"            = "rook-csi-rbd-provisioner"
    "csi.storage.k8s.io/provisioner-secret-namespace"       = local.namespace
    "csi.storage.k8s.io/controller-expand-secret-name"      = "rook-csi-rbd-provisioner"
    "csi.storage.k8s.io/controller-expand-secret-namespace" = local.namespace
    "csi.storage.k8s.io/node-stage-secret-name"             = "rook-csi-rbd-node"
    "csi.storage.k8s.io/node-stage-secret-namespace"        = local.namespace
  }
}
