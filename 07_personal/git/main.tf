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

variable "backup" {
  type = object({
    image               = string
    archive_secret_name = string
    sidecar = object({
      secret_name        = string
      secret_mount_point = string
      port               = number
      requests           = map(string)
      limits             = map(string)
    })
    sidecar_client_secret_name = string
  })
}

resource "kubernetes_config_map" "authorized_keys" {
  metadata {
    name      = "git-authorized-keys"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "git" }
  }
  data = {
    "all.pub" = join("\n", var.authorized_ssh_public_keys)
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
        labels = { "app.kubernetes.io/name" = "git" }
        annotations = {
          "confighash.skaia.cloud/authorizedkeys" = nonsensitive(md5(jsonencode(kubernetes_config_map.authorized_keys.data)))
        }
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
        volume {
          name = "backup-sc"
          secret {
            secret_name  = var.backup.sidecar.secret_name
            default_mode = "0600"
          }
        }
        container {
          name  = "main"
          image = "docker.io/jkarlos/git-server-docker@sha256:61b2d972b2f82ba31db22a090f3b9ac9388827556eca1b34879f449acb58995f"
          port {
            name           = "ssh"
            container_port = 22
            protocol       = "TCP"
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
            requests = { cpu = "1m", memory = "20Mi" }
            limits   = { memory = "1Gi" }
          }
        }
        container {
          name  = "backup-sc"
          image = var.backup.image
          args  = ["sidecar"]
          volume_mount {
            name       = "repositories"
            mount_path = "/data/git-repositories"
            read_only  = true
          }
          env {
            name  = "DATA_PATH"
            value = "/data/git-repositories"
          }
          env_from {
            secret_ref {
              name = var.backup.archive_secret_name
            }
          }
          volume_mount {
            name       = "backup-sc"
            mount_path = var.backup.sidecar.secret_mount_point
            read_only  = true
          }
          port {
            name           = "backup-sc"
            container_port = var.backup.sidecar.port
            protocol       = "TCP"
          }
          resources {
            requests = var.backup.sidecar.requests
            limits   = var.backup.sidecar.limits
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
      name         = "ssh"
      port         = 22
      protocol     = "TCP"
      app_protocol = "ssh"
      target_port  = "ssh"
    }
    port {
      name         = "backup-sc"
      port         = var.backup.sidecar.port
      protocol     = "TCP"
      app_protocol = "ssh"
      target_port  = "backup-sc"
    }
  }
}

module "backup" {
  source          = "../backup/sidecar_cron_job"
  name            = "git-backup"
  namespace       = var.namespace
  schedule        = "0 2 * * 3"
  sidecar_address = kubernetes_service.main.metadata[0].name
  common          = var.backup
}
