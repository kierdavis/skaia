resource "kubectl_manifest" "cluster" {
  depends_on = [helm_release.operator]
  yaml_body = yamlencode({
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
      resources = {
        mon = {
          requests = {
            cpu    = "90m"
            memory = "450Mi"
          }
          limits = {
            memory = "1Gi"
          }
        }
        mgr = {
          requests = {
            cpu    = "100m"
            memory = "590Mi"
          }
          limits = {
            memory = "1200Mi"
          }
        }
      }
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
  })
}
