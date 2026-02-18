terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "namespace" {
  type = string
}

variable "scratch_pvc_name" {
  type = string
}

variable "backup" {
  type = object({
    archive_secret_name = string
  })
}

locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))

  # timestamp format: "2012-11-01 22:08:41"
  accounts = tomap({
    kier = {
      email     = "me@kierdavis.com"
      timestamp = "2026-02-17 18:56:51"
      extract   = false
      upload    = false
    }
  })
}

resource "kubernetes_job" "extract" {
  for_each = {
    for key, value in local.accounts :
    key => value
    if value.extract
  }
  wait_for_completion = false
  metadata {
    name      = "takeout-extract-${each.key}"
    namespace = var.namespace
    labels    = { app = "takeout-extract", instance = each.key }
  }
  spec {
    backoff_limit = 0
    template {
      metadata {
        labels = { app = "takeout-extract", instance = each.key }
      }
      spec {
        restart_policy = "Never"
        affinity {
          node_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 50
              preference {
                match_expressions {
                  key      = "topology.kubernetes.io/zone"
                  operator = "In"
                  values   = ["z-adw"]
                }
              }
            }
          }
        }
        volume {
          name = "scratch"
          persistent_volume_claim {
            claim_name = var.scratch_pvc_name
          }
        }
        container {
          name  = "main"
          image = "docker.io/library/alpine@sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659"
          args = [
            "sh",
            "-c",
            <<-EOF
              cd /scratch
              for i in part*/*.tgz; do
                echo "$i..."
                tar -xzf "$i"
              done
            EOF
          ]
          volume_mount {
            name       = "scratch"
            sub_path   = "takeout/${each.value.email}"
            mount_path = "/scratch"
          }
          security_context {
            run_as_user  = local.globals.personal_uid
            run_as_group = local.globals.personal_uid
          }
        }
      }
    }
  }
}

resource "kubernetes_job" "upload" {
  for_each = {
    for key, value in local.accounts :
    key => value
    if value.upload
  }
  wait_for_completion = false
  metadata {
    name      = "takeout-upload-${each.key}"
    namespace = var.namespace
    labels    = { app = "takeout-upload", instance = each.key }
  }
  spec {
    backoff_limit = 0
    template {
      metadata {
        labels = { app = "takeout-upload", instance = each.key }
      }
      spec {
        restart_policy = "Never"
        affinity {
          node_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 50
              preference {
                match_expressions {
                  key      = "topology.kubernetes.io/zone"
                  operator = "In"
                  values   = ["z-adw"]
                }
              }
            }
          }
        }
        volume {
          name = "scratch"
          persistent_volume_claim {
            claim_name = var.scratch_pvc_name
          }
        }
        container {
          name  = "main"
          image = "docker.io/restic/restic@sha256:157243d77bc38be75a7b62b0c00453683251310eca414b9389ae3d49ea426c16"
          args = concat([
            "backup",
            "--exclude=lost+found",
            "--exclude=.nobackup",
            "--exclude=.Trash-*",
            "--host=generic",
            "--one-file-system",
            "--read-concurrency=4",
            "--time=${each.value.timestamp}",
            "--verbose",
            "/data/accounts/google/${each.value.email}",
          ])
          volume_mount {
            name       = "scratch"
            sub_path   = "takeout/${each.value.email}/Takeout"
            mount_path = "/data/accounts/google/${each.value.email}"
            read_only  = true
          }
          env_from {
            secret_ref {
              name = var.backup.archive_secret_name
            }
          }
          security_context {
            run_as_user  = local.globals.personal_uid
            run_as_group = local.globals.personal_uid
          }
        }
      }
    }
  }
}
