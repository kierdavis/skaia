resource "kubernetes_persistent_volume_claim" "downloads" {
  metadata {
    name      = "torrent-downloads"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "fs-media0"
    volume_mode        = "Filesystem"
    resources {
      requests = { storage = "1.25Ti" }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "video" {
  metadata {
    name      = "video"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "cephfs-video0"
    volume_mode        = "Filesystem"
    resources {
      requests = { storage = "200Gi" }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "music" {
  metadata {
    name      = "music"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "cephfs-music0"
    volume_mode        = "Filesystem"
    resources {
      requests = { storage = "100Gi" }
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
    volume_mode        = "Filesystem"
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
    volume_mode        = "Filesystem"
    resources {
      requests = { storage = "40Gi" }
    }
  }
}
