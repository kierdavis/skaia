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

variable "instance_name" {
  type = string
}

variable "server_name" {
  type = string
}

variable "server_password" {
  type      = string
  sensitive = true
  ephemeral = false # because it's persisted into a kubernetes_secret
}

# If true, the server will be listed in the in-game server browser.
# If false, the server can only be connected to entering the join code or IP+port printed in the server log.
# (This IP+port doesn't have to be internet-accessible, it's solely used as a server identifier.)
variable "public" {
  type    = bool
  default = false
}

variable "common" {
  type = object({
    image = string
  })
}

resource "kubernetes_secret" "main" {
  metadata {
    name      = "valheim-${var.instance_name}"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "valheim"
      "app.kubernetes.io/instance" = "valheim-${var.instance_name}"
    }
  }
  data = {
    "VALHEIM_SERVER_PASSWORD" = var.server_password
  }
}

resource "kubernetes_stateful_set" "main" {
  wait_for_rollout = false
  metadata {
    name      = "valheim-${var.instance_name}"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "valheim"
      "app.kubernetes.io/instance" = "valheim-${var.instance_name}"
    }
  }
  spec {
    replicas     = 1
    service_name = "valheim-${var.instance_name}"
    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "valheim"
        "app.kubernetes.io/instance" = "valheim-${var.instance_name}"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"     = "valheim"
          "app.kubernetes.io/instance" = "valheim-${var.instance_name}"
        }
      }
      spec {
        automount_service_account_token  = false
        enable_service_links             = false
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        affinity {
          node_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 50
              preference {
                match_expressions {
                  key      = "topology.kubernetes.io/zone"
                  operator = "NotIn"
                  values   = ["z-adw"]
                }
              }
            }
          }
        }
        init_container {
          name    = "chown"
          image   = var.common.image
          command = ["chown", "steam:steam", "/installation", "/state"]
          volume_mount {
            name       = "installation"
            mount_path = "/installation"
            read_only  = false
          }
          volume_mount {
            name       = "state"
            mount_path = "/state"
            read_only  = false
          }
          security_context {
            run_as_user  = 0
            run_as_group = 0
          }
        }
        init_container {
          name    = "install"
          image   = var.common.image
          command = ["bash", "./steamcmd.sh"]
          args = [
            "+force_install_dir", "/installation",
            "+login", "anonymous",
            "+app_update", "896660", "validate",
            "+quit",
          ]
          volume_mount {
            name       = "installation"
            mount_path = "/installation"
            read_only  = false
          }
        }
        container {
          name    = "main"
          image   = var.common.image
          command = ["./valheim_server.x86_64"]
          args = [
            "-name", var.server_name,
            "-world", "MyWorld",
            "-savedir", "/state",
            "-password", "$(VALHEIM_SERVER_PASSWORD)",
            "-public", var.public ? "1" : "0",
            "-crossplay",
          ]
          working_dir = "/installation"
          env_from {
            secret_ref {
              name = kubernetes_secret.main.metadata[0].name
            }
          }
          volume_mount {
            name       = "installation"
            mount_path = "/installation"
            read_only  = true
          }
          volume_mount {
            name       = "state"
            mount_path = "/state"
            read_only  = false
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "installation"
        labels = {
          "app.kubernetes.io/name"      = "valheim"
          "app.kubernetes.io/instance"  = "valheim-${var.instance_name}"
          "app.kubernetes.io/component" = "installation"
        }
        annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "45 4 * * *" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "rbd-gameservers0"
        volume_mode        = "Filesystem"
        resources {
          requests = { storage = "8Gi" }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "state"
        labels = {
          "app.kubernetes.io/name"      = "valheim"
          "app.kubernetes.io/instance"  = "valheim-${var.instance_name}"
          "app.kubernetes.io/component" = "state"
        }
        annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "50 4 * * *" }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "rbd-gameservers0"
        volume_mode        = "Filesystem"
        resources {
          requests = { storage = "32Gi" }
        }
      }
    }
  }
}
