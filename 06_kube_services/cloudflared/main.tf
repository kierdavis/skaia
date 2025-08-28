terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "account_id" {
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
    ingress = [
      {
        hostname       = "ensouled.skin"
        service        = "https://ensouled-skin.personal.svc.kube.skaia.cloud"
        origin_request = { origin_server_name = "ensouled.skin" }
      },
      {
        hostname       = "www.ensouled.skin"
        service        = "https://ensouled-skin.personal.svc.kube.skaia.cloud"
        origin_request = { origin_server_name = "www.ensouled.skin" }
      },
      { service = "http_status:404" },
    ]
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

resource "kubectl_manifest" "pod_monitor" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PodMonitor"
    metadata = {
      name      = "cloudflared"
      namespace = "system"
      labels    = { "app.kubernetes.io/name" = "cloudflared" }
    }
    spec = {
      selector = {
        matchLabels = { "app.kubernetes.io/name" = "cloudflared" }
      }
      podMetricsEndpoints = [{
        port   = "metrics"
        scheme = "http"
      }]
    }
  })
}

output "ingress_hostname" {
  value = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
}
