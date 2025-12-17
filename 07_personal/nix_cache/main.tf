terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

variable "namespace" {
  type = string
}

resource "kubectl_manifest" "bucket_claim" {
  yaml_body = yamlencode({
    apiVersion = "objectbucket.io/v1alpha1"
    kind       = "ObjectBucketClaim"
    metadata = {
      name      = "nix-cache"
      namespace = var.namespace
    }
    spec = {
      generateBucketName = "nix-cache"
      storageClassName   = "rgw-nix0"
    }
  })
}

output "config_map_name" {
  value = kubectl_manifest.bucket_claim.name
}

output "secret_name" {
  value = kubectl_manifest.bucket_claim.name
}

# Assign this to the http_proxy environment variable when accessing the bucket from Nix.
output "http_proxy" {
  value = "http://${kubernetes_service.proxy.metadata[0].name}.${kubernetes_service.proxy.metadata[0].namespace}.svc.kube.skaia.cloud:${local.proxy_service_port}"
}

output "confighash" {
  value = md5(kubectl_manifest.bucket_claim.uid)
}
