locals {
  fs_name    = "fs"
  fs_classes = toset(["gp0", "media0"])
}

resource "kubectl_manifest" "fs" {
  depends_on = [kubectl_manifest.cluster, kubernetes_job.imperative_config]
  yaml_body = yamlencode({
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephFilesystem"
    metadata = {
      name      = local.fs_name
      namespace = local.namespace
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
      dataPools = [
        for class in local.fs_classes :
        {
          name       = "data-${class}"
          replicated = { size = 2 }
          parameters = {
            crush_rule = "skaia_${class}"
            pg_num_min = "4"
            bulk       = "1"
          }
        }
      ]
      metadataServer = {
        activeCount       = 1 # Controls sharding, not redundancy.
        priorityClassName = "system-cluster-critical"
        #TODO:
        #placement = {
        #  topologySpreadConstraints = [{
        #    maxSkew = 1
        #    minDomains = 2
        #    topologyKey = "topology.rook.io/chassis"
        #    whenUnsatisfiable = "ScheduleAnyway"
        #    labelSelector = {
        #      matchLabels = {
        #        "app.kubernetes.io/name" = "ceph-mds"
        #        "app.kubernetes.io/part-of" = "fs"
        #      }
        #    }
        #  }]
        #}
      }
    }
  })
}

resource "kubernetes_storage_class" "fs" {
  for_each = local.fs_classes
  metadata {
    name   = "fs-${each.key}"
    labels = { "skaia.cloud/type" = "rook-ceph-fs" }
  }
  storage_provisioner    = "rook-ceph.cephfs.csi.ceph.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  parameters = {
    clusterID                                               = local.namespace
    fsName                                                  = kubectl_manifest.fs.name
    pool                                                    = "${kubectl_manifest.fs.name}-data-${each.key}"
    "csi.storage.k8s.io/provisioner-secret-name"            = "rook-csi-cephfs-provisioner"
    "csi.storage.k8s.io/provisioner-secret-namespace"       = local.namespace
    "csi.storage.k8s.io/controller-expand-secret-name"      = "rook-csi-cephfs-provisioner"
    "csi.storage.k8s.io/controller-expand-secret-namespace" = local.namespace
    "csi.storage.k8s.io/node-stage-secret-name"             = "rook-csi-cephfs-node"
    "csi.storage.k8s.io/node-stage-secret-namespace"        = local.namespace
  }
}
