locals {
  postgres_user    = "hydra"
  postgres_db_name = "hydra"
  postgres_host    = "${kubernetes_service.postgres.metadata[0].name}.${kubernetes_service.postgres.metadata[0].namespace}.svc.kube.skaia.cloud"

  dbi = "dbi:Pg:dbname=${local.postgres_db_name};host=${local.postgres_host};user=${local.postgres_user};"
}

resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "hydra-postgres"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "hydra-postgres"
      "app.kubernetes.io/component" = "database"
      "app.kubernetes.io/part-of"   = "hydra"
    }
  }
  data = {
    POSTGRES_PASSWORD = var.postgres_password
  }
}

resource "kubernetes_stateful_set" "postgres" {
  wait_for_rollout = false
  metadata {
    name      = "hydra-postgres"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "hydra-postgres"
      "app.kubernetes.io/component" = "database"
      "app.kubernetes.io/part-of"   = "hydra"
    }
  }
  spec {
    replicas     = 1
    service_name = "hydra-postgres"
    selector {
      match_labels = { "app.kubernetes.io/name" = "hydra-postgres" }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "hydra-postgres"
          "app.kubernetes.io/component" = "database"
          "app.kubernetes.io/part-of"   = "hydra"
        }
        annotations = {
          "confighash.skaia.cloud/secret" = nonsensitive(md5(jsonencode(kubernetes_secret.postgres.data)))
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
          env {
            name  = "POSTGRES_USER"
            value = local.postgres_user
          }
          env {
            name  = "POSTGRES_DB"
            value = local.postgres_db_name
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.postgres.metadata[0].name
            }
          }
          port {
            name           = "postgres"
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
        name = "state"
        labels = {
          "app.kubernetes.io/name"      = "hydra-postgres"
          "app.kubernetes.io/component" = "database"
          "app.kubernetes.io/part-of"   = "hydra"
        }
        annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "20 4 * * *" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "rbd-hydra0"
        volume_mode        = "Filesystem"
        resources {
          requests = { storage = "100Mi" }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "hydra-postgres"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "hydra-postgres"
      "app.kubernetes.io/component" = "database"
      "app.kubernetes.io/part-of"   = "hydra"
    }
  }
  spec {
    selector = { "app.kubernetes.io/name" = "hydra-postgres" }
    port {
      name        = "postgres"
      port        = 5432
      protocol    = "TCP"
      target_port = "postgres"
    }
  }
}
