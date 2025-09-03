terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    postgresql = {
      source = "cyrilgdn/postgresql"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

variable "namespace" {
  type = string
}

variable "cloudflare_account_id" {
  type = string
}

variable "cloudflare_tunnel_ingress_hostname" {
  type = string
}

variable "postgresql" {
  type = object({
    host = string
  })
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

module "image" {
  source         = "../../modules/stamp_image"
  repo_name      = "skaia-ensouled-skin"
  repo_namespace = local.globals.docker_hub.username
  flake_output   = "./${path.module}/../..#personal.ensouledSkin.image"
}

resource "random_password" "postgresql" {
  length = 20
}

resource "postgresql_role" "main" {
  name     = "ensouled_skin"
  login    = true
  password = random_password.postgresql.result
}

resource "postgresql_database" "main" {
  name  = "ensouled_skin"
  owner = postgresql_role.main.name
}

resource "postgresql_schema" "main" {
  name     = "public"
  database = postgresql_database.main.name
  owner    = postgresql_role.main.name
}

resource "tls_private_key" "origin" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "origin" {
  private_key_pem = tls_private_key.origin.private_key_pem
  dns_names       = ["ensouled.skin", "www.ensouled.skin"]
  subject {
    common_name = "ensouled.skin"
  }
}

resource "cloudflare_origin_ca_certificate" "main" {
  csr                = tls_cert_request.origin.cert_request_pem
  hostnames          = ["ensouled.skin", "www.ensouled.skin"]
  request_type       = "origin-ecc"
  requested_validity = 365
}

resource "kubernetes_secret" "main" {
  metadata {
    name      = "ensouled-skin"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "ensouled-skin" }
  }
  data = {
    "media.yaml" = file("${path.module}/../../secret/ensouled-skin-media.yaml")
    "origin.key" = tls_private_key.origin.private_key_pem
    "origin.crt" = cloudflare_origin_ca_certificate.main.certificate
    POSTGRES_DSN = "host=${var.postgresql.host} user=${postgresql_role.main.name} password=${random_password.postgresql.result} dbname=${postgresql_database.main.name}"
  }
}

resource "kubernetes_deployment" "main" {
  wait_for_rollout = false
  metadata {
    name      = "ensouled-skin"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "ensouled-skin" }
  }
  spec {
    replicas = 1
    selector {
      match_labels = { "app.kubernetes.io/name" = "ensouled-skin" }
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "ensouled-skin" }
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
          image = module.image.repo_tag
          env {
            name = "POSTGRES_DSN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.main.metadata[0].name
                key  = "POSTGRES_DSN"
              }
            }
          }
          volume_mount {
            name       = "secret"
            mount_path = "/secret"
          }
          port {
            name           = "main"
            container_port = 443
            protocol       = "TCP"
          }
        }
        volume {
          name = "secret"
          secret {
            secret_name = kubernetes_secret.main.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_network_policy" "main" {
  metadata {
    name      = "ensouled-skin"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "ensouled-skin" }
  }
  spec {
    policy_types = ["Ingress", "Egress"]
    pod_selector {
      match_labels = { "app.kubernetes.io/name" = "ensouled-skin" }
    }
    ingress {
      ports {
        port     = "main"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_service" "main" {
  metadata {
    name      = "ensouled-skin"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "ensouled-skin" }
  }
  spec {
    selector = { "app.kubernetes.io/name" = "ensouled-skin" }
    port {
      name         = "main"
      port         = 443
      protocol     = "TCP"
      app_protocol = "https"
      target_port  = "main"
    }
  }
}

data "cloudflare_zones" "main" {
  account = { id = var.cloudflare_account_id }
  match   = "all"
  name    = "ensouled.skin"
  status  = "active"
}

resource "cloudflare_dns_record" "main" {
  for_each = toset(["ensouled.skin", "www.ensouled.skin"])
  zone_id  = data.cloudflare_zones.main.result[0].id
  name     = each.key
  type     = "CNAME"
  content  = var.cloudflare_tunnel_ingress_hostname
  ttl      = 1 # means automatic
  proxied  = true
}

resource "cloudflare_ruleset" "main" {
  zone_id = data.cloudflare_zones.main.result[0].id
  name    = "main"
  phase   = "http_request_firewall_custom"
  kind    = "zone"
  rules = [
    {
      expression = "cf.client.bot or cf.worker.upstream_zone ne \"\""
      action     = "block"
    },
  ]
}
