resource "kubernetes_storage_class" "local" {
  metadata {
    name   = "local"
    labels = { "skaia.cloud/type" = "local" }
  }
  storage_provisioner = "kubernetes.io/no-provisioner"
  volume_binding_mode = "WaitForFirstConsumer"
}

resource "kubernetes_persistent_volume" "local" {
  for_each = {
    "annas-archive-downloads0" = { node = "pyrope", size = "931Gi" }
  }
  metadata {
    name = each.key
  }
  spec {
    access_modes                     = ["ReadWriteOnce"]
    capacity                         = { storage = each.value.size }
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = kubernetes_storage_class.local.metadata[0].name
    volume_mode                      = "Filesystem"
    persistent_volume_source {
      local {
        path = "/var/mnt/${each.key}"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = [each.value.node]
          }
        }
      }
    }
  }
}
