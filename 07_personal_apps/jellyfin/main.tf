terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "namespace" {
  type = string
}

variable "media_pvc_name" {
  type = string
}

variable "downloads_pvc_name" {
  type = string
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

module "image" {
  source         = "../../modules/container_image"
  repo_name      = "skaia-jellyfin"
  repo_namespace = local.globals.docker_hub.namespace
  src            = "${path.module}/image"
}

resource "kubernetes_stateful_set" "main" {
  wait_for_rollout = false
  metadata {
    name      = "jellyfin"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "jellyfin" }
  }
  spec {
    replicas     = 1
    service_name = "jellyfin"
    selector {
      match_labels = { "app.kubernetes.io/name" = "jellyfin" }
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "jellyfin" }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        # Must correspond to Jellyfin's hardware acceleration configuration.
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "hwcaps.skaia.cloud/qsv"
                  operator = "In"
                  values   = ["skylake"]
                }
              }
            }
          }
        }
        container {
          name  = "main"
          image = module.image.tag
          env {
            name  = "TZ"
            value = "Europe/London"
          }
          env {
            name  = "PUID"
            value = local.globals.personal_uid
          }
          env {
            name  = "PGID"
            value = local.globals.personal_uid
          }
          port {
            name           = "ui"
            container_port = 8096
            protocol       = "TCP"
          }
          volume_mount {
            name       = "state"
            mount_path = "/config"
            read_only  = false
          }
          volume_mount {
            name       = "transcoding-workspace"
            mount_path = "/config/data/transcodes"
            read_only  = false
          }
          volume_mount {
            name       = "media"
            mount_path = "/net/skaia/media"
            read_only  = true
          }
          volume_mount {
            name       = "downloads"
            mount_path = "/net/skaia/torrent-downloads"
            read_only  = true
          }
          resources {
            requests = {
              cpu                     = "250m"
              memory                  = "2Gi"
              "squat.ai/render-sleep" = "1"
            }
            limits = {
              memory                  = "7Gi"
              "squat.ai/render-sleep" = "1"
            }
          }
        }
        volume {
          name = "transcoding-workspace"
          ephemeral {
            volume_claim_template {
              metadata {
                labels      = { "app.kubernetes.io/name" = "jellyfin" }
                annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "5 4 * * *" }
              }
              spec {
                access_modes       = ["ReadWriteOnce"]
                storage_class_name = "blk-media0"
                resources {
                  requests = { storage = "30Gi" }
                }
              }
            }
          }
        }
        volume {
          name = "media"
          persistent_volume_claim {
            claim_name = var.media_pvc_name
          }
        }
        volume {
          name = "downloads"
          persistent_volume_claim {
            claim_name = var.downloads_pvc_name
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name        = "state"
        labels      = { "app.kubernetes.io/name" = "jellyfin" }
        annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "20 4 * * *" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "blk-gp0"
        resources {
          requests = { storage = "2Gi" }
        }
      }
    }
  }
}

resource "kubernetes_service" "main" {
  metadata {
    name      = "jellyfin"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "jellyfin" }
  }
  spec {
    selector = { "app.kubernetes.io/name" = "jellyfin" }
    port {
      name         = "ui"
      port         = 80
      protocol     = "TCP"
      app_protocol = "http"
      target_port  = "ui"
    }
  }
}
