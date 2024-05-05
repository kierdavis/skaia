resource "kubernetes_manifest" "cluster" {
  manifest = {
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephCluster"
    metadata = {
      name      = local.namespace
      namespace = local.namespace
    }
    spec = {
      cephVersion = {
        allowUnsupported = false
        image            = "quay.io/ceph/ceph:v${local.ceph_version}"
      }
      cleanupPolicy = {
        confirmation = ""
      }
      crashCollector = {
        disable = true
      }
      csi = {
        readAffinity = {
          enabled = true
        }
      }
      dashboard = {
        enabled = true
        port    = 80
        ssl     = false
      }
      dataDirHostPath = "/var/lib/rook"
      disruptionManagement = {
        managePodBudgets = true
      }
      logCollector = {
        enabled = false
      }
      mgr = {
        count = 1
        modules = [
          { name = "pg_autoscaler", enabled = true },
          #{ name = "prometheus",    enabled = true }, # TODO
          { name = "rook", enabled = true },
        ]
      }
      mon = {
        allowMultiplePerNode = false
        count                = 3
      }
      monitoring = {
        enabled = false # TODO
      }
      removeOSDsIfOutAndSafeToRemove = false
      storage = {
        devices = [
          { name = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_500GB_S2RBNX0J113462W" },
          { name = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi-disk-1" },
          { name = "/dev/disk/by-partlabel/OSD0" },
        ]
        useAllDevices = false
        useAllNodes   = true
      }
    }
  }
}

resource "kubernetes_manifest" "fs" {
  manifest = {
    apiVersion = "ceph.rook.io/v1"
    kind       = "CephFilesystem"
    metadata = {
      name      = "fs"
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
        {
          name       = "data-gp0"
          replicated = { size = 2 }
          parameters = {
            crush_rule = "skaia_gp0"
            pg_num_min = "1"
            bulk       = "1"
          }
        },
        {
          name       = "data-media0"
          replicated = { size = 2 }
          parameters = {
            crush_rule = "skaia_media0"
            pg_num_min = "1"
            bulk       = "1"
          }
        },
      ]
      metadataServer = {
        activeCount       = 1 # Controls sharding, not redundancy.
        priorityClassName = "system-cluster-critical"
      }
    }
  }
  depends_on = [kubernetes_job.imperative_config]
}
