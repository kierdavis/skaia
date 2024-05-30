terraform {
  required_providers {
    external = {
      source = "hashicorp/external"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

locals {
  namespace = "system"

  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

data "kubernetes_namespace" "kube_system" {
  metadata {
    name = "kube-system"
  }
}

resource "time_rotating" "license" {
  rotation_days = 180
}

resource "terraform_data" "license" {
  triggers_replace = time_rotating.license.id
  provisioner "local-exec" {
    command = <<-EOF
      exec curl --request POST --header 'Content-Type: application/json' \
        --data-binary "$payload" https://license-issuer.appscode.com/issue-license \
        > "$out"
    EOF
    environment = {
      payload = jsonencode({
        name    = local.globals.stash.license.name
        email   = local.globals.stash.license.email
        product = "stash"
        cluster = data.kubernetes_namespace.kube_system.metadata[0].uid
        tos     = "true"
        token   = local.globals.stash.license.api_token
      })
      out = "${path.module}/license.txt"
    }
  }
}

data "external" "license" {
  depends_on = [terraform_data.license]
  program    = ["jq", "--raw-input", "--slurp", "--compact-output", "{txt:.}", "${path.module}/license.txt"]
}

resource "kubernetes_secret" "license" {
  metadata {
    name      = "stash-license"
    namespace = local.namespace
  }
  data = { "key.txt" = data.external.license.result.txt }
}

resource "helm_release" "main" {
  name       = "stash"
  chart      = "stash-community"
  repository = "https://charts.appscode.com/stable/"
  version    = "0.34.0"
  namespace  = local.namespace
  values = [yamlencode({
    fullnameOverride  = "stash"
    licenseSecretName = kubernetes_secret.license.metadata[0].name
    operator = {
      resources = {
        requests = {
          cpu    = "1m"
          memory = "55Mi"
        }
        limits = {
          memory = "200Mi"
        }
      }
    }
    monitoring = {
      agent    = "prometheus.io/operator"
      backup   = true
      operator = true
    }
    nameOverride = "stash"
    pushgateway = {
      resources = {
        requests = {
          cpu    = "1m"
          memory = "20Mi"
        }
        limits = {
          memory = "200Mi"
        }
      }
    }
  })]
}
