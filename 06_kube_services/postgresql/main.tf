# Shared Postgres instance for system stuff.

terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
}

locals {
  # Password for the "postgres" user.
  password = sensitive("REDACTED")
}

resource "helm_release" "main" {
  name      = "postgresql"
  chart     = "oci://registry-1.docker.io/bitnamicharts/postgresql"
  version   = "15.5.20"
  namespace = "system"
  values = [yamlencode({
    architecture     = "standalone"
    auth             = { postgresPassword = local.password }
    clusterDomain    = "kube.skaia.cloud"
    fullnameOverride = "postgresql"
    metrics = {
      enabled        = true
      serviceMonitor = { enabled = true }
    }
    primary = {
      networkPolicy = {
        allowExternal = false
        enabled       = false # TODO: enable this
        extraIngress = [
          # TODO: allow prometheus to scrape
          # { ports: [ ... ], from: [ ... ] }, etc.
        ]
      }
      pdb = { create = false }
      persistence = {
        enabled      = true
        accessModes  = ["ReadWriteOnce"]
        size         = "16Gi"
        storageClass = "blk-gp0"
        annotations  = { "reclaimspace.csiaddons.openshift.io/schedule" = "45 4 * * *" }
      }
    }
    readReplicas   = { replicaCount = 0 }
    serviceAccount = { create = false }
    shmVolume      = { enabled = false }
  })]
}

output "provider_config" {
  value = {
    host     = "postgresql.system.svc.kube.skaia.cloud"
    username = "postgres"
    password = local.password
    sslmode  = "disable" # TODO?
  }
}
