terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "kubernetes_namespace" "main" {
  metadata {
    name = "prometheus"
    labels = {
      "pod-security.kubernetes.io/audit"           = "baseline"
      "pod-security.kubernetes.io/audit-version"   = "latest"
      "pod-security.kubernetes.io/enforce"         = "baseline"
      "pod-security.kubernetes.io/enforce-version" = "latest"
      "pod-security.kubernetes.io/warn"            = "baseline"
      "pod-security.kubernetes.io/warn-version"    = "latest"
    }
  }
}

locals {
  namespace = kubernetes_namespace.main.metadata[0].name
}

resource "helm_release" "main" {
  name       = "main"
  chart      = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = "58.4.0"
  namespace  = local.namespace
  values = [yamlencode({
    alertmanager = {
      alertmanagerSpec = {
        replicas = 1
        resources = {
          requests = {
            cpu    = "1m"
            memory = "25Mi"
          }
        }
        storage = {
          volumeClaimTemplate = {
            spec = {
              accessModes      = ["ReadWriteOnce"]
              storageClassName = "blk-gp0"
              resources        = { requests = { storage : "2Gi" } }
            }
          }
        }
      }
    }
    cleanPrometheusOperatorObjectNames = true
    fullnameOverride                   = "prometheus"
    grafana = {
      fullnameOverride = "grafana"
      persistence = {
        accessModes      = ["ReadWriteOnce"]
        enabled          = true
        size             = "4Gi"
        storageClassName = "blk-gp0"
        type             = "sts"
      }
    }
    "kube-state-metrics" = {
      fullnameOverride = "kube-state-metrics"
    }
    prometheus = {
      prometheusSpec = {
        replicas = 1
        resources = {
          requests = {
            cpu    = "250m"
            memory = "1Gi"
          }
        }
        retentionSize = "15GiB"
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              accessModes      = ["ReadWriteOnce"]
              storageClassName = "blk-gp0"
              resources        = { requests = { storage : "16Gi" } }
            }
          }
        }
      }
    }
    prometheusOperator = {
      fullnameOverride = "operator"
    }
  })]
}
