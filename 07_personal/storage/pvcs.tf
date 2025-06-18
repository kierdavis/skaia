resource "kubernetes_persistent_volume_claim" "downloads" {
  metadata {
    name      = "torrent-downloads-x"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "cephfs-video0"
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

resource "kubernetes_persistent_volume_claim" "photography" {
  metadata {
    name      = "photography"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "cephfs-photography0"
    volume_mode        = "Filesystem"
    resources {
      requests = { storage = "100Gi" }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "projects" {
  metadata {
    name      = "projects-x"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "cephfs-documents0"
    volume_mode        = "Filesystem"
    resources {
      requests = { storage = "100Gi" }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "documents" {
  metadata {
    name      = "documents-x"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "cephfs-documents0"
    volume_mode        = "Filesystem"
    resources {
      requests = { storage = "40Gi" }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "tfstate" {
  metadata {
    name      = "tfstate"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "cephfs-documents0"
    volume_mode        = "Filesystem"
    resources {
      requests = { storage = "1Gi" }
    }
  }
}
