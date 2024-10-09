resource "kubernetes_persistent_volume_claim" "downloads" {
  metadata {
    name      = "torrent-downloads"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "fs-media0"
    resources {
      requests = { storage = "1Ti" }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "media" {
  metadata {
    name      = "media"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "fs-media0"
    resources {
      requests = { storage = "200Gi" }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "projects" {
  metadata {
    name      = "projects"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "fs-gp0"
    resources {
      requests = { storage = "100Gi" }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "documents" {
  metadata {
    name      = "documents"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "fs-gp0"
    resources {
      requests = { storage = "40Gi" }
    }
  }
}
