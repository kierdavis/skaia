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
        affinity {
          node_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              preference {
                match_expressions {
                  key      = "topology.kubernetes.io/region"
                  operator = "In"
                  values   = ["r-man"]
                }
              }
            }
          }
        }
        container {
          name  = "main"
          image = "docker.io/linuxserver/jellyfin@sha256:8e2c0ce0156eae6cba0487d5d1bc03d821e0b3f6a51a72d966517ec8aa9e90d4"
          env {
            name  = "TZ"
            value = "Europe/London"
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
            name       = "transcode-cache"
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
              cpu               = "500m"
              memory            = "2.5Gi"
              "squat.ai/render" = "1"
            }
            limits = {
              "squat.ai/render" = "1"
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
        name   = "state"
        labels = { "app.kubernetes.io/name" = "jellyfin" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "blk-gp0"
        resources {
          requests = { storage = "2Gi" }
        }
      }
    }
    volume_claim_template {
      metadata {
        name   = "transcode-cache"
        labels = { "app.kubernetes.io/name" = "jellyfin" }
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
      target_port  = "ui"
      app_protocol = "http"
    }
  }
}
