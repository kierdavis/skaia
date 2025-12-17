terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
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

variable "todoist_api_token" {
  type      = string
  sensitive = true
  ephemeral = false
}

variable "trmnl_private_plugin_auth_token" {
  type      = string
  sensitive = true
  ephemeral = false
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
  labels  = { "app.kubernetes.io/name" = "trmnl-todoist" }
}

resource "tls_private_key" "origin" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "origin" {
  private_key_pem = tls_private_key.origin.private_key_pem
  dns_names       = ["trmnl-todoist.kierdavis.com"]
  subject {
    common_name = "trmnl-todoist.kierdavis.com"
  }
}

resource "cloudflare_origin_ca_certificate" "main" {
  csr                = tls_cert_request.origin.cert_request_pem
  hostnames          = ["trmnl-todoist.kierdavis.com"]
  request_type       = "origin-ecc"
  requested_validity = 365
}

resource "kubernetes_secret" "main" {
  metadata {
    name      = "trmnl-todoist"
    namespace = var.namespace
    labels    = local.labels
  }
  data = {
    "origin.crt"                    = cloudflare_origin_ca_certificate.main.certificate
    "origin.key"                    = tls_private_key.origin.private_key_pem
    TODOIST_API_TOKEN               = var.todoist_api_token
    TRMNL_PRIVATE_PLUGIN_AUTH_TOKEN = var.trmnl_private_plugin_auth_token
  }
}

module "image" {
  source         = "../../modules/stamp_image"
  repo_name      = "skaia-trmnl-todoist"
  repo_namespace = local.globals.docker_hub.username
  flake_output   = "./${path.module}/../..#personal.trmnlTodoist.image"
}

resource "kubernetes_deployment" "main" {
  wait_for_rollout = false
  metadata {
    name      = "trmnl-todoist"
    namespace = var.namespace
    labels    = local.labels
  }
  spec {
    replicas = 1
    selector {
      match_labels = local.labels
    }
    template {
      metadata {
        labels = local.labels
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
            name = "TODOIST_API_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.main.metadata[0].name
                key  = "TODOIST_API_TOKEN"
              }
            }
          }
          env {
            name = "TRMNL_PRIVATE_PLUGIN_AUTH_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.main.metadata[0].name
                key  = "TRMNL_PRIVATE_PLUGIN_AUTH_TOKEN"
              }
            }
          }
          env {
            name  = "TLS_CERT"
            value = "/secret/origin.crt"
          }
          env {
            name  = "TLS_KEY"
            value = "/secret/origin.key"
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
    name      = "trmnl-todoist"
    namespace = var.namespace
    labels    = local.labels
  }
  spec {
    policy_types = ["Ingress", "Egress"]
    pod_selector {
      match_labels = local.labels
    }
    ingress {
      ports {
        port     = "main"
        protocol = "TCP"
      }
    }
    egress {
      to {
        namespace_selector {
          match_labels = { "kubernetes.io/metadata.name" = "kube-system" }
        }
        pod_selector {
          match_labels = { "k8s-app" = "kube-dns" }
        }
      }
      ports {
        port     = 53
        protocol = "TCP"
      }
      ports {
        port     = 53
        protocol = "UDP"
      }
    }
    egress {
      # To Todoist API, which could have any IP.
      ports {
        port     = 443
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_service" "main" {
  metadata {
    name      = "trmnl-todoist"
    namespace = var.namespace
    labels    = local.labels
  }
  spec {
    selector = local.labels
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
  name    = "kierdavis.com"
}

resource "cloudflare_dns_record" "main" {
  zone_id = one(data.cloudflare_zones.main.result).id
  name    = "trmnl-todoist.kierdavis.com"
  type    = "CNAME"
  content = "in.skaia.cloud"
  ttl     = 1 # means automatic
  proxied = true
}
