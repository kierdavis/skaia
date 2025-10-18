locals {
  cephfs_storage_classes = {
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
    music0 = {
      data_pool_spec = {
        replicated    = { size = 2 }
        failureDomain = "host"
        parameters = {
          pg_num = "2"
          bulk   = "1"
        }
      }
    }
    photography0 = {
      data_pool_spec = {
        replicated    = { size = 2 }
        failureDomain = "host"
        crushRoot     = "z-adw"
        parameters = {
          pg_num = "4"
          bulk   = "1"
        }
      }
    }
    scratch0 = {
      data_pool_spec = {
        replicated    = { size = 2 }
        failureDomain = "host"
        parameters = {
          pg_num = "4"
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
          pg_num = "8"
          bulk   = "1"
        }
      }
    }
  }
}

resource "kubectl_manifest" "cephfs" {
  depends_on = [kubectl_manifest.cluster, kubernetes_job.imperative_config]
  yaml_body = yamlencode({
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephFilesystem"
    metadata = {
      name      = "cephfs"
      namespace = local.namespace
    }
    spec = {
      metadataPool = {
        replicated    = { size = 2 }
        failureDomain = "host"
        parameters = {
          pg_num = "2"
          bulk   = "0"
        }
      }
      dataPools = [
        for name, info in local.cephfs_storage_classes :
        merge(info.data_pool_spec, { name = name })
      ]
      metadataServer = {
        activeCount       = 1 # Controls sharding, not redundancy.
        priorityClassName = "system-cluster-critical"
        placement = {
          nodeAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [{
              weight = 50
              preference = {
                matchExpressions = [{
                  key      = "topology.kubernetes.io/zone"
                  operator = "In"
                  values   = ["z-adw"]
                }]
              }
            }]
          }
          topologySpreadConstraints = [{
            maxSkew           = 1
            topologyKey       = "topology.rook.io/chassis"
            whenUnsatisfiable = "DoNotSchedule"
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name"    = "ceph-mds"
                "app.kubernetes.io/part-of" = "fs"
              }
            }
          }]
        }
        resources = {
          requests = { cpu = "100m", memory = "200Mi" }
          limits   = { memory = "2Gi" }
        }
      }
    }
  })
}

resource "kubernetes_storage_class" "cephfs" {
  for_each = local.cephfs_storage_classes
  metadata {
    name   = "cephfs-${each.key}"
    labels = { "skaia.cloud/type" = "cephfs" }
  }
  storage_provisioner    = "rook-ceph.cephfs.csi.ceph.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  parameters = {
    clusterID                                               = local.namespace
    fsName                                                  = kubectl_manifest.cephfs.name
    pool                                                    = "${kubectl_manifest.cephfs.name}-${each.key}"
    "csi.storage.k8s.io/provisioner-secret-name"            = "rook-csi-cephfs-provisioner"
    "csi.storage.k8s.io/provisioner-secret-namespace"       = local.namespace
    "csi.storage.k8s.io/controller-expand-secret-name"      = "rook-csi-cephfs-provisioner"
    "csi.storage.k8s.io/controller-expand-secret-namespace" = local.namespace
    "csi.storage.k8s.io/node-stage-secret-name"             = "rook-csi-cephfs-node"
    "csi.storage.k8s.io/node-stage-secret-namespace"        = local.namespace
  }
}
