terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    postgresql = {
      source = "cyrilgdn/postgresql"
    }
    random = {
      source = "hashicorp/random"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

variable "namespace" {
  type = string
}

variable "nix_signing_secret_key" {
  type      = string
  sensitive = true
  ephemeral = false
}

variable "projects_pvc_name" {
  type = string
}

variable "postgresql" {
  type = object({
    host = string
  })
}

variable "nix_cache" {
  type = object({
    config_map_name = string
    secret_name     = string
    confighash      = string
  })
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

output "ssh_public_key" {
  value = replace(tls_private_key.ssh.public_key_openssh, "\n", " hydra")
}

module "image" {
  source         = "../../modules/stamp_image"
  repo_name      = "skaia-hydra"
  repo_namespace = local.globals.docker_hub.username
  flake_output   = "./${path.module}/../..#personal.hydra.image"
}

resource "random_password" "postgresql" {
  length = 20
}

resource "postgresql_role" "main" {
  name     = "hydra"
  login    = true
  password = random_password.postgresql.result
}

resource "postgresql_database" "main" {
  name  = "hydra"
  owner = postgresql_role.main.name
}

resource "postgresql_schema" "main" {
  name     = "public"
  database = postgresql_database.main.name
  owner    = postgresql_role.main.name
}

locals {
  dbi = "dbi:Pg:dbname=${postgresql_database.main.name};host=${var.postgresql.host};user=${postgresql_role.main.name};"
}

resource "kubernetes_secret" "main" {
  metadata {
    name      = "hydra"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "hydra"
      "app.kubernetes.io/component" = "webapp"
      "app.kubernetes.io/part-of"   = "hydra"
    }
  }
  data = {
    id_ed25519             = tls_private_key.ssh.private_key_openssh
    nix-signing-secret-key = var.nix_signing_secret_key
    pgpass                 = "*:*:*:*:${random_password.postgresql.result}\n"
  }
}

resource "kubernetes_stateful_set" "main" {
  wait_for_rollout = false
  metadata {
    name      = "hydra"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "hydra"
      "app.kubernetes.io/component" = "webapp"
      "app.kubernetes.io/part-of"   = "hydra"
    }
  }
  spec {
    replicas     = 1
    service_name = "hydra"
    selector {
      match_labels = { "app.kubernetes.io/name" = "hydra" }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "hydra"
          "app.kubernetes.io/component" = "webapp"
          "app.kubernetes.io/part-of"   = "hydra"
        }
        annotations = {
          "confighash.skaia.cloud/cache-bucket" = var.nix_cache.confighash
          "confighash.skaia.cloud/secret"       = nonsensitive(md5(jsonencode(kubernetes_secret.main.data)))
        }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        init_container {
          name  = "init"
          image = module.image.repo_tag
          args  = ["hydra-init"]
          env {
            name  = "HYDRA_DBI"
            value = local.dbi
          }
          volume_mount {
            name       = "secret"
            sub_path   = "pgpass"
            mount_path = "/root/.pgpass"
            read_only  = true
          }
        }
        container {
          name  = "main"
          image = module.image.repo_tag
          env {
            name  = "HYDRA_DBI"
            value = local.dbi
          }
          env_from {
            config_map_ref {
              name = var.nix_cache.config_map_name
            }
          }
          env_from {
            secret_ref {
              name = var.nix_cache.secret_name
            }
          }
          volume_mount {
            name       = "secret"
            sub_path   = "id_ed25519"
            mount_path = "/root/.ssh/id_ed25519"
            read_only  = true
          }
          volume_mount {
            name       = "secret"
            sub_path   = "nix-signing-secret-key"
            mount_path = "/nix-signing-secret-key"
            read_only  = true
          }
          volume_mount {
            name       = "secret"
            sub_path   = "pgpass"
            mount_path = "/root/.pgpass"
            read_only  = true
          }
          volume_mount {
            name       = "session-data-x"
            mount_path = "/var/lib/hydra/www"
            read_only  = false
          }
          volume_mount {
            name       = "logs-x"
            mount_path = "/var/lib/hydra/build-logs"
            read_only  = false
          }
          volume_mount {
            name       = "projects"
            mount_path = "/net/skaia/projects"
            read_only  = true
          }
          port {
            name           = "ui"
            container_port = 80
            protocol       = "TCP"
          }
          port {
            name           = "metrics"
            container_port = 9198
            protocol       = "TCP"
          }
          readiness_probe {
            http_get {
              path = "/"
              port = "ui"
            }
            initial_delay_seconds = 3
            period_seconds        = 5
            timeout_seconds       = 2
            success_threshold     = 1
            failure_threshold     = 3
          }
          resources {
            requests = { cpu = "10m", memory = "500Mi" }
            limits   = { memory = "6Gi" }
          }
        }
        volume {
          name = "secret"
          secret {
            secret_name  = kubernetes_secret.main.metadata[0].name
            default_mode = "0600"
          }
        }
        volume {
          name = "projects"
          persistent_volume_claim {
            claim_name = var.projects_pvc_name
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "session-data-x"
        labels = {
          "app.kubernetes.io/name"      = "hydra"
          "app.kubernetes.io/component" = "webapp"
          "app.kubernetes.io/part-of"   = "hydra"
        }
        annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "20 4 * * *" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "rbd-hydra0"
        volume_mode        = "Filesystem"
        resources {
          requests = { storage = "10Mi" }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "logs-x"
        labels = {
          "app.kubernetes.io/name"      = "hydra"
          "app.kubernetes.io/component" = "webapp"
          "app.kubernetes.io/part-of"   = "hydra"
        }
        annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "25 4 * * *" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "rbd-hydra0"
        volume_mode        = "Filesystem"
        resources {
          requests = { storage = "2Gi" }
        }
      }
    }
  }
}

resource "kubernetes_service" "main" {
  metadata {
    name      = "hydra"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "hydra"
      "app.kubernetes.io/component" = "webapp"
      "app.kubernetes.io/part-of"   = "hydra"
    }
  }
  spec {
    selector = { "app.kubernetes.io/name" = "hydra" }
    port {
      name         = "ui"
      port         = 80
      protocol     = "TCP"
      app_protocol = "http"
      target_port  = "ui"
    }
    port {
      name         = "metrics"
      port         = 9198
      protocol     = "TCP"
      app_protocol = "http"
      target_port  = "metrics"
    }
  }
}

resource "kubectl_manifest" "service_monitor" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "hydra"
      namespace = var.namespace
      labels = {
        "app.kubernetes.io/name"      = "hydra"
        "app.kubernetes.io/component" = "webapp"
        "app.kubernetes.io/part-of"   = "hydra"
      }
    }
    spec = {
      selector = {
        matchLabels = { "app.kubernetes.io/name" = "hydra" }
      }
      endpoints = [{
        port   = "metrics"
        scheme = "http"
      }]
    }
  })
}
