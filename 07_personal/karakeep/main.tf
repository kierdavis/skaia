terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

variable "namespace" {
  type = string
}

locals {
  version = "0.27.1"
}

resource "kubectl_manifest" "asset_bucket_claim" {
  yaml_body = yamlencode({
    apiVersion = "objectbucket.io/v1alpha1"
    kind       = "ObjectBucketClaim"
    metadata = {
      name      = "karakeep-assets"
      namespace = var.namespace
    }
    spec = {
      generateBucketName = "karakeep-assets"
      storageClassName   = "rgw-gp0"
    }
  })
}

resource "random_password" "nextauth" {
  length = 20
}

resource "random_password" "prometheus" {
  length  = 20
  special = false
}

resource "kubernetes_secret" "main" {
  metadata {
    name      = "karakeep"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "karakeep"
      "app.kubernetes.io/component" = "webapp"
      "app.kubernetes.io/part-of"   = "karakeep"
    }
  }
  data = {
    MEILI_MASTER_KEY      = random_password.meilisearch.result
    NEXTAUTH_SECRET       = random_password.nextauth.result
    PROMETHEUS_AUTH_TOKEN = random_password.prometheus.result
  }
}

resource "kubernetes_stateful_set" "main" {
  wait_for_rollout = false
  metadata {
    name      = "karakeep"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "karakeep"
      "app.kubernetes.io/component" = "webapp"
      "app.kubernetes.io/part-of"   = "karakeep"
    }
  }
  spec {
    replicas     = 1
    service_name = "karakeep"
    selector {
      match_labels = { "app.kubernetes.io/name" = "karakeep" }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "karakeep"
          "app.kubernetes.io/component" = "webapp"
          "app.kubernetes.io/part-of"   = "karakeep"
        }
        annotations = {
          "confighash.skaia.cloud/asset-bucket" = md5(kubectl_manifest.asset_bucket_claim.uid)
          "confighash.skaia.cloud/secret"       = nonsensitive(md5(jsonencode(kubernetes_secret.main.data)))
        }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        container {
          name  = "main"
          image = "ghcr.io/karakeep-app/karakeep:${local.version}"
          env {
            name  = "ASSET_STORE_S3_ACCESS_KEY_ID"
            value = "$(AWS_ACCESS_KEY_ID)"
          }
          env {
            name  = "ASSET_STORE_S3_BUCKET"
            value = "$(BUCKET_NAME)"
          }
          env {
            name  = "ASSET_STORE_S3_ENDPOINT"
            value = "http://$(BUCKET_HOST):$(BUCKET_PORT)"
          }
          env {
            name  = "ASSET_STORE_S3_FORCE_PATH_STYLE"
            value = "true"
          }
          env {
            name  = "ASSET_STORE_S3_REGION"
            value = "$(BUCKET_REGION)"
          }
          env {
            name  = "ASSET_STORE_S3_SECRET_ACCESS_KEY"
            value = "$(AWS_SECRET_ACCESS_KEY)"
          }
          env {
            name  = "BROWSER_WEB_URL"
            value = "http://${kubernetes_service.chrome.metadata[0].name}.${var.namespace}.svc:9222"
          }
          env {
            name  = "DATA_DIR"
            value = "/data"
          }
          env {
            name  = "KARAKEEP_VERSION"
            value = local.version
          }
          env {
            name  = "MEILI_ADDR"
            value = "http://${kubernetes_service.meilisearch.metadata[0].name}.${var.namespace}.svc:7700"
          }
          env {
            name  = "NEXTAUTH_URL"
            value = "http://${kubernetes_service.main.metadata[0].name}.${var.namespace}.svc.kube.skaia.cloud/"
          }
          env {
            name  = "TZ"
            value = "Europe/London"
          }
          env {
            name  = "WORKERS_PORT"
            value = "9001"
          }
          env_from {
            config_map_ref {
              name = kubectl_manifest.asset_bucket_claim.name
            }
          }
          env_from {
            secret_ref {
              name = kubectl_manifest.asset_bucket_claim.name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.main.metadata[0].name
            }
          }
          volume_mount {
            name       = "database"
            mount_path = "/data"
            read_only  = false
          }
          port {
            name           = "main"
            container_port = 3000
            protocol       = "TCP"
          }
          port {
            name           = "worker-metrics"
            container_port = 9001
            protocol       = "TCP"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "database"
        labels = {
          "app.kubernetes.io/name"      = "karakeep"
          "app.kubernetes.io/component" = "webapp"
          "app.kubernetes.io/part-of"   = "karakeep"
        }
        annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "55 4 * * *" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "rbd-gp0"
        volume_mode        = "Filesystem"
        resources {
          requests = { storage = "1Gi" }
        }
      }
    }
  }
}

resource "kubernetes_service" "main" {
  metadata {
    name      = "karakeep"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "karakeep"
      "app.kubernetes.io/component" = "webapp"
      "app.kubernetes.io/part-of"   = "karakeep"
    }
  }
  spec {
    selector = { "app.kubernetes.io/name" = "karakeep" }
    port {
      name         = "main"
      port         = 80
      protocol     = "TCP"
      app_protocol = "http"
      target_port  = "main"
    }
  }
}

resource "kubectl_manifest" "pod_monitor" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PodMonitor"
    metadata = {
      name      = "karakeep"
      namespace = var.namespace
      labels = {
        "app.kubernetes.io/name"      = "karakeep"
        "app.kubernetes.io/component" = "webapp"
        "app.kubernetes.io/part-of"   = "karakeep"
      }
    }
    spec = {
      selector = {
        matchLabels = { "app.kubernetes.io/name" = "karakeep" }
      }
      podMetricsEndpoints = [
        {
          port   = "main"
          scheme = "http"
          path   = "/api/metrics"
          authorization = {
            type = "Bearer"
            credentials = {
              name = kubernetes_secret.main.metadata[0].name
              key  = "PROMETHEUS_AUTH_TOKEN"
            }
          }
        },
        {
          port   = "worker-metrics"
          scheme = "http"
        },
      ]
    }
  })
}
