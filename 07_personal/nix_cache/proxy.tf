# HTTP proxy that does nothing except drop the "Content-Encoding: aws-chunked"
# header from the response since it confuses libarchive.

locals {
  proxy_service_port = 80
}

resource "kubernetes_config_map" "proxy" {
  metadata {
    name      = "nix-cache-proxy"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "nix-cache-proxy" }
  }
  data = {
    "addons.py" = <<-EOF
      class ModifyResponse:
        def responseheaders(self, flow):
          if "rook-ceph-rgw" in flow.request.host:
            if flow.response.headers.get("Content-Encoding") == "aws-chunked":
              del flow.response.headers["Content-Encoding"]
      addons = [ModifyResponse()]
    EOF
  }
}

resource "kubernetes_deployment" "proxy" {
  wait_for_rollout = false
  metadata {
    name      = "nix-cache-proxy"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "nix-cache-proxy" }
  }
  spec {
    replicas = 2
    selector {
      match_labels = { "app.kubernetes.io/name" = "nix-cache-proxy" }
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "nix-cache-proxy" }
        annotations = {
          "confighash.skaia.cloud/config" = md5(jsonencode(kubernetes_config_map.proxy.data))
        }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        container {
          name  = "main"
          image = "docker.io/mitmproxy/mitmproxy@sha256:743b6cdc817211d64bc269f5defacca8d14e76e647fc474e5c7244dbcb645141" # tag "12"
          args  = ["mitmdump", "-s", "/config/addons.py"]
          volume_mount {
            name       = "config"
            mount_path = "/config"
          }
          port {
            name           = "http-proxy"
            container_port = 8080
            protocol       = "TCP"
          }
        }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.proxy.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "proxy" {
  metadata {
    name      = "nix-cache-proxy"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "nix-cache-proxy" }
  }
  spec {
    selector = { "app.kubernetes.io/name" = "nix-cache-proxy" }
    port {
      name         = "http-proxy"
      port         = local.proxy_service_port
      protocol     = "TCP"
      app_protocol = "http"
      target_port  = "http-proxy"
    }
  }
}
