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

variable "authorized_ssh_public_keys" {
  type = set(string)
}

variable "archive_secret_name" {
  type = string
}

variable "restic_sidecar_image" {
  type = string
}

locals {
  authorized_keys = join("\n", var.authorized_ssh_public_keys)
}

resource "kubernetes_config_map" "authorized_keys" {
  metadata {
    name      = "git-authorized-keys"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "git" }
  }
  data = {
    "all.pub" = local.authorized_keys
  }
}

resource "kubernetes_stateful_set" "main" {
  wait_for_rollout = false
  metadata {
    name      = "git"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "git" }
  }
  spec {
    replicas     = 1
    service_name = "git"
    selector {
      match_labels = { "app.kubernetes.io/name" = "git" }
    }
    template {
      metadata {
        labels      = { "app.kubernetes.io/name" = "git" }
        annotations = { "skaia.cloud/confighash" = md5(local.authorized_keys) }
      }
      spec {
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        volume {
          name = "keys"
          config_map {
            name = kubernetes_config_map.authorized_keys.metadata[0].name
          }
        }
        container {
          name  = "main"
          image = "docker.io/jkarlos/git-server-docker@sha256:61b2d972b2f82ba31db22a090f3b9ac9388827556eca1b34879f449acb58995f"
          port {
            name           = "ssh"
            container_port = 22
          }
          volume_mount {
            name       = "repositories"
            mount_path = "/git-server/repos"
          }
          volume_mount {
            name       = "keys"
            mount_path = "/git-server/keys"
            read_only  = true
          }
          resources {
            requests = {
              cpu    = "1m"
              memory = "5Mi"
            }
          }
        }
        container {
          name  = "backup"
          image = var.restic_sidecar_image
          env {
            name  = "SCHEDULE"
            value = "0 2 * * 3"
          }
          env {
            name  = "DIR"
            value = "/data/git-repositories"
          }
          env_from {
            secret_ref {
              name = var.archive_secret_name
            }
          }
          volume_mount {
            name       = "repositories"
            mount_path = "/data/git-repositories"
            read_only  = true
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name        = "repositories"
        labels      = { "app.kubernetes.io/name" = "git" }
        annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "15 4 * * *" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "rbd-documents0"
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
    name      = "git"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "git" }
  }
  spec {
    selector = { "app.kubernetes.io/name" = "git" }
    port {
      name        = "ssh"
      port        = 22
      target_port = "ssh"
    }
  }
}
