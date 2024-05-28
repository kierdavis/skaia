terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

data "terraform_remote_state" "talos" {
  backend = "local"
  config = {
    path = "${path.module}/../../04_talos/terraform.tfstate"
  }
}

resource "kubernetes_namespace" "main" {
  metadata {
    name = "prometheus"
    labels = {
      # Need privileged due to node-exporter's use of hostPaths.
      "pod-security.kubernetes.io/audit"           = "privileged"
      "pod-security.kubernetes.io/audit-version"   = "latest"
      "pod-security.kubernetes.io/enforce"         = "privileged"
      "pod-security.kubernetes.io/enforce-version" = "latest"
      "pod-security.kubernetes.io/warn"            = "privileged"
      "pod-security.kubernetes.io/warn-version"    = "latest"
    }
  }
}

locals {
  namespace         = kubernetes_namespace.main.metadata[0].name
  node_endpoint_set = toset([for _, addr in data.terraform_remote_state.talos.outputs.node_endpoints : addr])
}

resource "tls_private_key" "etcd_client" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "etcd_client" {
  private_key_pem = tls_private_key.etcd_client.private_key_pem
  subject {
    common_name = "prometheus"
  }
}

resource "tls_locally_signed_cert" "etcd_client" {
  ca_cert_pem           = data.terraform_remote_state.talos.outputs.etcd_ca_cert
  ca_private_key_pem    = data.terraform_remote_state.talos.outputs.etcd_ca_key
  cert_request_pem      = tls_cert_request.etcd_client.cert_request_pem
  validity_period_hours = 2 * 365 * 24
  early_renewal_hours   = 365 * 24
  allowed_uses          = ["client_auth", "digital_signature", "key_encipherment"]
}

resource "kubernetes_secret" "etcd" {
  metadata {
    name      = "etcd"
    namespace = local.namespace
  }
  data = {
    "ca.crt"     = data.terraform_remote_state.talos.outputs.etcd_ca_cert
    "client.crt" = tls_locally_signed_cert.etcd_client.cert_pem
    "client.key" = tls_private_key.etcd_client.private_key_pem
  }
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
              resources        = { requests = { storage = "2Gi" } }
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
    kubeControllerManager = {
      service = { selector = { k8s-app = "kube-controller-manager" } }
    }
    kubeEtcd = {
      endpoints = local.node_endpoint_set
      service   = { port = 2379, targetPort = 2379 }
      serviceMonitor = {
        caFile   = "/etc/prometheus/secrets/${kubernetes_secret.etcd.metadata[0].name}/ca.crt"
        certFile = "/etc/prometheus/secrets/${kubernetes_secret.etcd.metadata[0].name}/client.crt"
        keyFile  = "/etc/prometheus/secrets/${kubernetes_secret.etcd.metadata[0].name}/client.key"
        scheme   = "https"
      }
    }
    kubeProxy = {
      service = { selector = { k8s-app = "kube-proxy" } }
    }
    kubeScheduler = {
      service = { selector = { k8s-app = "kube-scheduler" } }
    }
    kube-state-metrics = {
      fullnameOverride = "kube-state-metrics"
    }
    prometheus = {
      prometheusSpec = {
        podMonitorNamespaceSelector         = { any = true }
        podMonitorSelector                  = {}
        podMonitorSelectorNilUsesHelmValues = false
        replicas                            = 1
        resources = {
          requests = {
            cpu    = "250m"
            memory = "1Gi"
          }
        }
        retentionSize                           = "15GiB"
        ruleNamespaceSelector                   = { any = true }
        ruleSelector                            = {}
        ruleSelectorNilUsesHelmValues           = false
        secrets                                 = [kubernetes_secret.etcd.metadata[0].name]
        serviceMonitorNamespaceSelector         = { any = true }
        serviceMonitorSelector                  = {}
        serviceMonitorSelectorNilUsesHelmValues = false
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              accessModes      = ["ReadWriteOnce"]
              storageClassName = "blk-gp0"
              resources        = { requests = { storage = "16Gi" } }
            }
          }
        }
      }
    }
    prometheusOperator = {
      fullnameOverride = "operator"
    }
    prometheus-node-exporter = {
      fullnameOverride = "node-exporter"
    }
  })]
}

resource "kubectl_manifest" "rules" {
  depends_on = [helm_release.main]
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "skaia"
      namespace = "system"
    }
    spec = {
      groups = [
        {
          name = "scheduling-sanity.rules"
          rules = [
            {
              alert  = "NoCPURequest"
              expr   = <<-EOF
                kube_pod_container_info unless on (namespace, pod, container) kube_pod_container_resource_requests{resource="cpu"}
              EOF
              labels = { severity = "warning" }
              annotations = {
                summary     = "Container doesn't define a CPU resource request."
                description = "Container {{$labels.container}} in pod {{$labels.pod}} in namespace {{$labels.namespace}} doesn't define a CPU resource request, so it may be scheduled onto a node with insufficient available CPU time."
              }
            },
            {
              alert  = "NoMemoryRequest"
              expr   = <<-EOF
                kube_pod_container_info unless on (namespace, pod, container) kube_pod_container_resource_requests{resource="memory"}
              EOF
              labels = { severity = "warning" }
              annotations = {
                summary     = "Container doesn't define a memory resource request."
                description = "Container {{$labels.container}} in pod {{$labels.pod}} in namespace {{$labels.namespace}} doesn't define a memory resource request, so it may be scheduled onto a node with insufficient available memory."
              }
            },
          ]
        },
      ]
    }
  })
}
