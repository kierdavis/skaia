terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

locals {
  apps = merge({
    ensouled_skin = {
      match_hostnames = toset(["ensouled.skin", "www.ensouled.skin"])
      origin = {
        namespace    = "personal"
        url          = "https://ensouled-skin.personal.svc.kube.skaia.cloud"
        pod_selector = { "app.kubernetes.io/name" = "ensouled-skin" }
        pod_port     = "main"
      }
    }
    trmnl_todoist = {
      match_hostnames = toset(["trmnl-todoist.kierdavis.com"])
      origin = {
        namespace    = "personal"
        url          = "https://trmnl-todoist.personal.svc.kube.skaia.cloud"
        pod_selector = { "app.kubernetes.io/name" = "trmnl-todoist" }
        pod_port     = "main"
      }
    }
  }, yamldecode(file("${path.module}/../../secret/cloudflared_apps.yaml")))
}

variable "account_id" {
  type = string
}

variable "zone_id" {
  type = string
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "main" {
  account_id = var.account_id
  name       = "skaia-0"
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "main" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id
  config = {
    ingress = concat(
      concat([
        for app_name, app in local.apps :
        [
          for hostname in app.match_hostnames :
          {
            hostname       = hostname
            service        = app.origin.url
            origin_request = { origin_server_name = hostname }
          }
        ]
      ]...),
      [{ service = "http_status:404" }],
    )
    origin_request = {
      connect_timeout = 10
      http2_origin    = true
      no_tls_verify   = false
      tls_timeout     = 10
    }
  }
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "main" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id
}

resource "kubernetes_secret" "main" {
  metadata {
    name      = "cloudflared"
    namespace = "system"
    labels    = { "app.kubernetes.io/name" = "cloudflared" }
  }
  data = { token = data.cloudflare_zero_trust_tunnel_cloudflared_token.main.token }
}

resource "kubernetes_deployment" "main" {
  wait_for_rollout = false
  metadata {
    name      = "cloudflared"
    namespace = "system"
    labels    = { "app.kubernetes.io/name" = "cloudflared" }
  }
  spec {
    replicas = 2
    selector {
      match_labels = { "app.kubernetes.io/name" = "cloudflared" }
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "cloudflared" }
        annotations = {
          "confighash.skaia.cloud/secret" = nonsensitive(md5(jsonencode(kubernetes_secret.main.data)))
        }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "topology.rook.io/chassis"
          when_unsatisfiable = "DoNotSchedule"
          label_selector {
            match_labels = { "app.kubernetes.io/name" = "cloudflared" }
          }
        }
        container {
          name  = "main"
          image = "docker.io/cloudflare/cloudflared@sha256:b77d84e8704db38db22c22661cf7e56468c526e3a6a5fe9c8b7c151452fa1472" # "latest" tag
          args  = ["tunnel", "--metrics=0.0.0.0:9090", "run", "--token-file=/secret/token"]
          volume_mount {
            name       = "secret"
            mount_path = "/secret"
          }
          port {
            name           = "metrics"
            container_port = 9090
            protocol       = "TCP"
          }
          resources {
            requests = { cpu = "5m", memory = "40Mi" }
            limits   = { memory = "150Mi" }
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

data "cloudflare_ip_ranges" "main" {}

resource "kubernetes_network_policy" "main" {
  metadata {
    name      = "cloudflared"
    namespace = "system"
    labels    = { "app.kubernetes.io/name" = "cloudflared" }
  }
  spec {
    policy_types = ["Ingress", "Egress"]
    pod_selector {
      match_labels = { "app.kubernetes.io/name" = "cloudflared" }
    }
    ingress {
      from {
        namespace_selector {
          match_labels = { "kubernetes.io/metadata.name" = "prometheus" }
        }
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "prometheus" }
        }
      }
      ports {
        port     = "metrics"
        protocol = "TCP"
      }
    }
    dynamic "egress" {
      for_each = setunion(
        toset(data.cloudflare_ip_ranges.main.ipv4_cidrs),
        toset(data.cloudflare_ip_ranges.main.ipv6_cidrs),
      )
      content {
        to {
          ip_block { cidr = egress.key }
        }
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
    dynamic "egress" {
      for_each = local.apps
      content {
        to {
          namespace_selector {
            match_labels = { "kubernetes.io/metadata.name" = egress.value.origin.namespace }
          }
          pod_selector {
            match_labels = egress.value.origin.pod_selector
          }
        }
        ports {
          port     = egress.value.origin.pod_port
          protocol = "TCP"
        }
      }
    }
  }
}

resource "cloudflare_dns_record" "main" {
  zone_id = var.zone_id
  name    = "in.skaia.cloud"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
  ttl     = 1 # means automatic
  proxied = true
  comment = "managed by skaia terraform"
}
