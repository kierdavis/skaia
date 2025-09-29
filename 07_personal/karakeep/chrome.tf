resource "kubernetes_deployment" "chrome" {
  wait_for_rollout = false
  metadata {
    name      = "karakeep-chrome"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "karakeep-chrome"
      "app.kubernetes.io/component" = "chrome"
      "app.kubernetes.io/part-of"   = "karakeep"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "karakeep-chrome"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "karakeep-chrome"
          "app.kubernetes.io/component" = "chrome"
          "app.kubernetes.io/part-of"   = "karakeep"
        }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        container {
          name  = "main"
          image = "gcr.io/zenika-hub/alpine-chrome:124"
          command = [
            "chromium-browser",
            "--headless",
            "--no-sandbox",
            "--disable-gpu",
            "--disable-dev-shm-usage",
            "--remote-debugging-address=0.0.0.0",
            "--remote-debugging-port=9222",
            "--hide-scrollbars",
          ]
          port {
            name           = "main"
            container_port = 9222
            protocol       = "TCP"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "chrome" {
  metadata {
    name      = "karakeep-chrome"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "karakeep-chrome"
      "app.kubernetes.io/component" = "chrome"
      "app.kubernetes.io/part-of"   = "karakeep"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "karakeep-chrome"
    }
    port {
      name         = "main"
      port         = 9222
      protocol     = "TCP"
      app_protocol = "http"
      target_port  = "main"
    }
  }
}
