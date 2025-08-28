terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

variable "namespace" {
  type = string
}

resource "random_password" "main" {
  length = 20
}

resource "kubernetes_secret" "main" {
  metadata {
    name      = "postgresql"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "postgresql" }
  }
  data = { POSTGRES_PASSWORD = random_password.main.result }
}

resource "kubernetes_stateful_set" "main" {
  wait_for_rollout = false
  metadata {
    name      = "postgresql"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "postgresql" }
  }
  spec {
    replicas     = 1
    service_name = "postgresql"
    selector {
      match_labels = { "app.kubernetes.io/name" = "postgresql" }
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "postgresql" }
        annotations = {
          "confighash.skaia.cloud/secret" = nonsensitive(md5(jsonencode(kubernetes_secret.main.data)))
        }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        container {
          name  = "main"
          image = "docker.io/library/postgres@sha256:c0aab7962b283cf24a0defa5d0d59777f5045a7be59905f21ba81a20b1a110c9"
          env_from {
            secret_ref {
              name = kubernetes_secret.main.metadata[0].name
            }
          }
          port {
            name           = "main"
            container_port = 5432
            protocol       = "TCP"
          }
          volume_mount {
            name       = "state"
            sub_path   = "data"
            mount_path = "/var/lib/postgresql/data"
            read_only  = false
          }
          resources {
            requests = { cpu = "2m", memory = "60Mi" }
            limits   = { memory = "200Mi" }
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name        = "state"
        labels      = { "app.kubernetes.io/name" = "postgresql" }
        annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "20 4 * * *" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "rbd-gp0"
        volume_mode        = "Filesystem"
        resources {
          requests = { storage = "512Mi" }
        }
      }
    }
  }
}

resource "kubernetes_service" "main" {
  metadata {
    name      = "postgresql"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "postgresql" }
  }
  spec {
    selector = { "app.kubernetes.io/name" = "postgresql" }
    port {
      name         = "main"
      port         = 5432
      protocol     = "TCP"
      app_protocol = "postgresql"
      target_port  = "main"
    }
  }
}

output "host" {
  value = "${kubernetes_service.main.metadata[0].name}.${var.namespace}.svc.kube.skaia.cloud"
}

output "username" {
  value = "postgres"
}

output "password" {
  value = random_password.main.result
}

output "sslmode" {
  value = "disable"
}
