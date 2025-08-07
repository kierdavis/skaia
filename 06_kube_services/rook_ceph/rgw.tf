locals {
  rgw_storage_classes = {
    nix0 = {
      data_pool_spec = {
        replicated    = { size = 2 }
        failureDomain = "host"
        parameters = {
          pg_num = "4"
          bulk   = "1"
        }
      }
    }
  }
}

resource "kubectl_manifest" "rgw_root_pool" {
  depends_on = [kubectl_manifest.cluster, module.imperative_config]
  yaml_body = yamlencode({
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephBlockPool"
    metadata = {
      name      = "rgw-root"
      namespace = local.namespace
    }
    spec = {
      name          = ".rgw.root"
      application   = "rgw"
      replicated    = { size = 2 }
      failureDomain = "host"
      parameters = {
        pg_num = "2"
        bulk   = "0"
      }
    }
  })
}

resource "kubectl_manifest" "rgw_metadata_pool" {
  depends_on = [kubectl_manifest.cluster, module.imperative_config]
  yaml_body = yamlencode({
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephBlockPool"
    metadata = {
      name      = "rgw-metadata"
      namespace = local.namespace
    }
    spec = {
      application   = "rgw"
      replicated    = { size = 2 }
      failureDomain = "host"
      parameters = {
        pg_num = "2"
        bulk   = "0"
      }
    }
  })
}

resource "kubectl_manifest" "rgw_data_pool" {
  for_each   = local.rgw_storage_classes
  depends_on = [kubectl_manifest.cluster, module.imperative_config]
  yaml_body = yamlencode({
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephBlockPool"
    metadata = {
      name      = "rgw-${each.key}"
      namespace = local.namespace
    }
    spec = merge(each.value.data_pool_spec, {
      application = "rgw"
    })
  })
}

resource "kubectl_manifest" "object_store" {
  for_each   = local.rgw_storage_classes
  depends_on = [kubectl_manifest.rgw_root_pool]
  yaml_body = yamlencode({
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephObjectStore"
    metadata = {
      name      = each.key
      namespace = local.namespace
    }
    spec = {
      sharedPools = {
        metadataPoolName                   = kubectl_manifest.rgw_metadata_pool.name
        dataPoolName                       = kubectl_manifest.rgw_data_pool[each.key].name
        preserveRadosNamespaceDataOnDelete = true
      }
      gateway = {
        instances = 1
        port      = 80
        resources = {
          requests = { cpu = "20m", memory = "200Mi" }
          limits   = { memory = "1Gi" }
        }
      }
    }
  })
}

resource "kubernetes_storage_class" "rgw" {
  for_each = local.rgw_storage_classes
  metadata {
    name   = "rgw-${each.key}"
    labels = { "skaia.cloud/type" = "rgw" }
  }
  storage_provisioner = "rook-ceph.ceph.rook.io/bucket"
  reclaim_policy      = "Delete"
  parameters = {
    objectStoreName      = kubectl_manifest.object_store[each.key].name
    objectStoreNamespace = local.namespace
  }
}

