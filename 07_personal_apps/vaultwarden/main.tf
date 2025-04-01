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

resource "kubernetes_stateful_set" "main" {
  wait_for_rollout = false
  metadata {
    name      = "vaultwarden"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "vaultwarden" }
  }
  spec {
    replicas     = 1
    service_name = "vaultwarden"
    selector {
      match_labels = { "app.kubernetes.io/name" = "vaultwarden" }
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "vaultwarden" }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        container {
          name  = "main"
          image = "docker.io/vaultwarden/server@sha256:4e28425bad4bd13568e1779f682ff7e441eca2ecd079bd77cfcba6e4eaf1b999"
          env {
            name  = "DOMAIN"
            value = "http://vaultwarden.${var.namespace}.svc.kube.skaia.cloud"
          }
          env {
            name  = "INVITATIONS_ALLOWED"
            value = "false"
          }
          env {
            name  = "SIGNUPS_ALLOWED"
            value = "true"
          }
          env {
            name  = "TZ"
            value = "Europe/London"
          }
          port {
            name           = "http"
            container_port = 80
            protocol       = "TCP"
          }
          volume_mount {
            name       = "state"
            mount_path = "/data"
            read_only  = false
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name   = "state"
        labels = { "app.kubernetes.io/name" = "vaultwarden" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "blk-gp0"
        volume_mode        = "Filesystem"
        resources {
          requests = { storage = "1Gi" }
        }
      }
    }
  }
}

resource "kubernetes_service" "main" {
  metadata {
    name      = "vaultwarden"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "vaultwarden" }
  }
  spec {
    selector = { "app.kubernetes.io/name" = "vaultwarden" }
    port {
      name         = "http"
      port         = 80
      protocol     = "TCP"
      app_protocol = "http"
      target_port  = "http"
    }
  }
}
