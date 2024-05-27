terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

variable "namespace" {
  type = string
}

resource "kubernetes_persistent_volume_claim" "downloads" {
  metadata {
    name      = "torrent-downloads"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "fs-media0"
    resources {
      requests = { storage = "750Gi" }
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
      requests = { storage = "100Gi" }
    }
  }
}

resource "kubernetes_secret" "archive" {
  metadata {
    name      = "archive"
    namespace = var.namespace
  }
  data = {
    B2_ACCOUNT_ID   = local.globals.b2.account_id
    B2_ACCOUNT_KEY  = local.globals.b2.account_key
    RESTIC_PASSWORD = local.globals.b2.archive.restic_password
  }
}

resource "kubectl_manifest" "media_backup_repo" {
  yaml_body = yamlencode({
    apiVersion = "stash.appscode.com/v1alpha1"
    kind       = "Repository"
    metadata = {
      name      = "media"
      namespace = var.namespace
    }
    spec = {
      backend = {
        b2 = {
          bucket = local.globals.b2.archive.bucket
          prefix = "/skaia/stash-0/personal/media"
        }
        storageSecretName = kubernetes_secret.archive.metadata[0].name
      }
      wipeOut = false
      usagePolicy = {
        allowedNamespaces = {
          from = "Selector"
          selector = {
            matchExpressions = [{
              key      = "kubernetes.io/metadata.name"
              operator = "In"
              values   = [var.namespace]
            }]
          }
        }
      }
    }
  })
}

resource "kubectl_manifest" "media_backup_config" {
  yaml_body = yamlencode({
    apiVersion = "stash.appscode.com/v1beta1"
    kind       = "BackupConfiguration"
    metadata = {
      name      = "media"
      namespace = var.namespace
    }
    spec = {
      driver = "Restic"
      repository = {
        name      = "media"
        namespace = var.namespace
      }
      retentionPolicy = {
        name        = "personal-media"
        keepDaily   = 7
        keepWeekly  = 5
        keepMonthly = 12
        keepYearly  = 1000
        prune       = true
      }
      runtimeSettings = {
        container = {
          securityContext = {
            runAsUser  = local.globals.shared_fs_uid
            runAsGroup = local.globals.shared_fs_uid
          }
        }
      }
      schedule = "0 2 * * 2"
      target = {
        exclude = ["lost+found", ".nobackup"]
        ref = {
          apiVersion = "v1"
          kind       = "PersistentVolumeClaim"
          name       = kubernetes_persistent_volume_claim.media.metadata[0].name
        }
      }
      task    = { name = "pvc-backup" }
      timeOut = "6h"
    }
  })
}

output "downloads_pvc_name" {
  value = kubernetes_persistent_volume_claim.downloads.metadata[0].name
}

output "media_pvc_name" {
  value = kubernetes_persistent_volume_claim.media.metadata[0].name
}

output "archive_secret_name" {
  value = kubernetes_secret.archive.metadata[0].name
}
