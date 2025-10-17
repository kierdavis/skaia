terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    postgresql = {
      source = "cyrilgdn/postgresql"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

variable "namespace" {
  type = string
}

variable "postgresql" {
  type = object({
    host = string
  })
}

locals {
  globals   = yamldecode(file("${path.module}/../../globals.yaml"))
  instances = toset(["prod", "dev"])
}

module "image" {
  source         = "../../modules/stamp_image"
  repo_name      = "skaia-redstore"
  repo_namespace = local.globals.docker_hub.username
  flake_output   = "./${path.module}/../..#personal.redstore.image"
}

resource "random_password" "postgresql" {
  for_each = local.instances
  length   = 20
}

resource "postgresql_role" "main" {
  for_each = local.instances
  name     = "redstore-${each.key}"
  login    = true
  password = random_password.postgresql[each.key].result
}

resource "postgresql_database" "main" {
  for_each = local.instances
  name     = "redstore-${each.key}"
  owner    = postgresql_role.main[each.key].name
}

resource "postgresql_schema" "main" {
  for_each = local.instances
  name     = "public"
  database = postgresql_database.main[each.key].name
  owner    = postgresql_role.main[each.key].name
}

resource "kubernetes_secret" "main" {
  for_each = local.instances
  metadata {
    name      = "redstore-${each.key}"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "redstore"
      "app.kubernetes.io/instance" = each.key
    }
  }
  data = {
    PGHOST     = var.postgresql.host
    PGUSER     = postgresql_role.main[each.key].name
    PGPASSWORD = random_password.postgresql[each.key].result
    PGDATABASE = postgresql_database.main[each.key].name
  }
}

resource "kubernetes_deployment" "main" {
  for_each         = local.instances
  wait_for_rollout = false
  metadata {
    name      = "redstore-${each.key}"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "redstore"
      "app.kubernetes.io/instance" = each.key
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "redstore"
        "app.kubernetes.io/instance" = each.key
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"     = "redstore"
          "app.kubernetes.io/instance" = each.key
        }
        annotations = {
          "confighash.skaia.cloud/secret" = nonsensitive(md5(jsonencode(kubernetes_secret.main[each.key].data)))
        }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        container {
          name  = "main"
          image = module.image.repo_tag
          args = [
            "-p", "8080",
            "-s", "postgresql",
            "-t", "host='$(PGHOST)',user='$(PGUSER)',password='$(PGPASSWORD)',database='$(PGDATABASE)'",
            "-v",
            "default",
          ]
          env_from {
            secret_ref {
              name = kubernetes_secret.main[each.key].metadata[0].name
            }
          }
          port {
            name           = "main"
            container_port = 8080
            protocol       = "TCP"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "main" {
  for_each = local.instances
  metadata {
    name      = "redstore-${each.key}"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "redstore"
      "app.kubernetes.io/instance" = each.key
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name"     = "redstore"
      "app.kubernetes.io/instance" = each.key
    }
    port {
      name         = "main"
      port         = 80
      protocol     = "TCP"
      app_protocol = "http"
      target_port  = "main"
    }
  }
}
