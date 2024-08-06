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

variable "archive_secret_name" {
  type = string
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

resource "kubernetes_config_map" "authorized_keys" {
  metadata {
    name      = "git-authorized-keys"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "git" }
  }
  data = {
    "all.pub" = join("\n", local.globals.authorized_ssh.public_keys)
  }
}

resource "kubernetes_stateful_set" "main" {
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
        labels = { "app.kubernetes.io/name" = "git" }
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
        storage_class_name = "blk-gp0"
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
