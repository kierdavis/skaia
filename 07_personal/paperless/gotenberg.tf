resource "kubernetes_deployment" "gotenberg" {
  wait_for_rollout = false
  metadata {
    name      = "paperless-gotenberg"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "paperless-gotenberg"
      "app.kubernetes.io/component" = "gotenberg"
      "app.kubernetes.io/part-of"   = "paperless"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "paperless-gotenberg"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "paperless-gotenberg"
          "app.kubernetes.io/component" = "gotenberg"
          "app.kubernetes.io/part-of"   = "paperless"
        }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        container {
          name  = "main"
          image = "docker.io/gotenberg/gotenberg@sha256:437b9cd3c35113774818b30767ae267cb08f04d88125410c135cdd5952c0571e"
          args  = ["gotenberg", "--chromium-disable-javascript=true", "--chromium-allow-list=file:///tmp/.*"]
          port {
            name           = "main"
            container_port = 3000
            protocol       = "TCP"
          }
          resources {
            requests = { cpu = "1m", memory = "100Mi" }
            limits   = { memory = "400Mi" }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "gotenberg" {
  metadata {
    name      = "paperless-gotenberg"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "paperless-gotenberg"
      "app.kubernetes.io/component" = "gotenberg"
      "app.kubernetes.io/part-of"   = "paperless"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "paperless-gotenberg"
    }
    port {
      name         = "main"
      port         = 3000
      protocol     = "TCP"
      app_protocol = "http"
      target_port  = "main"
    }
  }
}
