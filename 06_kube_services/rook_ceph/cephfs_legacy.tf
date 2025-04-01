resource "kubectl_manifest" "cephfs_legacy" {
  depends_on = [kubectl_manifest.cluster, kubernetes_job.imperative_config]
  yaml_body = yamlencode({
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephFilesystem"
    metadata = {
      name      = "fs"
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
        {
          name          = "data-media0"
          replicated    = { size = 2 }
          failureDomain = "host"
          crushRoot     = "z-adw"
          parameters = {
            pg_num = "16"
            bulk   = "1"
          }
        },
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
            whenUnsatisfiable = "ScheduleAnyway"
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name"    = "ceph-mds"
                "app.kubernetes.io/part-of" = "fs"
              }
            }
          }]
        }
        resources = {
          requests = {
            cpu    = "300m"
            memory = "300Mi"
          }
          limits = {
            memory = "2Gi"
          }
        }
      }
    }
  })
}

resource "kubernetes_storage_class" "cephfs_legacy" {
  for_each = toset(["media0"])
  metadata {
    name   = "fs-${each.key}"
    labels = { "skaia.cloud/type" = "cephfs" }
  }
  storage_provisioner    = "rook-ceph.cephfs.csi.ceph.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  parameters = {
    clusterID                                               = local.namespace
    fsName                                                  = kubectl_manifest.cephfs_legacy.name
    pool                                                    = "${kubectl_manifest.cephfs_legacy.name}-data-${each.key}"
    "csi.storage.k8s.io/provisioner-secret-name"            = "rook-csi-cephfs-provisioner"
    "csi.storage.k8s.io/provisioner-secret-namespace"       = local.namespace
    "csi.storage.k8s.io/controller-expand-secret-name"      = "rook-csi-cephfs-provisioner"
    "csi.storage.k8s.io/controller-expand-secret-namespace" = local.namespace
    "csi.storage.k8s.io/node-stage-secret-name"             = "rook-csi-cephfs-node"
    "csi.storage.k8s.io/node-stage-secret-namespace"        = local.namespace
  }
}
