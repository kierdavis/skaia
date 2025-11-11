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
          { name = "prometheus", enabled = true },
          { name = "rook", enabled = true },
        ]
      }
      mon = {
        allowMultiplePerNode = true
        count                = 3
      }
      monitoring = {
        enabled         = true
        metricsDisabled = false
      }
      placement = {
        mon = {
          tolerations = [
            {
              effect   = "NoSchedule"
              key      = "skaia.cloud/control-only"
              operator = "Exists"
            },
          ]
        }
      }
      removeOSDsIfOutAndSafeToRemove = false
      resources = {
        exporter = {
          requests = { cpu = "15m", memory = "20Mi" }
          limits   = { memory = "100Mi" }
        }
        mgr = {
          requests = { cpu = "100m", memory = "590Mi" }
          limits   = { memory = "1200Mi" }
        }
        mon = {
          requests = { cpu = "90m", memory = "450Mi" }
          limits   = { memory = "1Gi" }
        }
        osd = {
          requests = { cpu = "90m", memory = "1Gi" }
          limits   = { memory = "2Gi" }
        }
      }
      storage = {
        devices = [
          { name = "/dev/disk/by-id/ata-MTFDDAK2T0TBN-1AR1ZABHA_UGXWT01ZRCNAHP" },
          { name = "/dev/disk/by-partlabel/OSD0" },
        ]
        useAllDevices = false
        useAllNodes   = true
      }
    }
  })
}
