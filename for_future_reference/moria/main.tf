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

variable "steamcmd_image" {
  type = string
}

resource "kubernetes_config_map" "main" {
  metadata {
    name      = "moria"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "moria" }
  }
  data = {
    "MoriaServerConfig.ini"      = <<-EOF
    
    EOF
    "MoriaServerPermissions.txt" = <<-EOF
    
    EOF
    "MoriaServerRules.txt"       = <<-EOF
    
    EOF
  }
}

resource "kubernetes_stateful_set" "main" {
  wait_for_rollout = false
  metadata {
    name      = "moria"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "moria" }
  }
  spec {
    replicas     = 1
    service_name = "moria"
    selector {
      match_labels = { "app.kubernetes.io/name" = "moria" }
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "moria" }
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
          image   = var.steamcmd_image
          command = ["chown", "steam:steam", "/installation", ] #"/state"]
          volume_mount {
            name       = "installation"
            mount_path = "/installation"
            read_only  = false
          }
          #volume_mount {
          #  name       = "state"
          #  mount_path = "/state"
          #  read_only  = false
          #}
          security_context {
            run_as_user  = 0
            run_as_group = 0
          }
        }
        init_container {
          name  = "install"
          image = var.steamcmd_image
          args = [
            "./steamcmd.sh",
            "+force_install_dir", "/installation",
            "+login", "anonymous",
            "+app_update", "3349480", "validate",
            "+quit",
          ]
          volume_mount {
            name       = "installation"
            mount_path = "/installation"
            read_only  = false
          }
        }
        container {
          name  = "main"
          image = var.steamcmd_image
          args  = ["sleep", "infinity"]
          #args = ["wine", "MoriaServer.exe"]
          working_dir = "/installation"
          #env_from {
          #  secret_ref {
          #    name = kubernetes_secret.main.metadata[0].name
          #  }
          #}
          volume_mount {
            name       = "installation"
            mount_path = "/installation"
            read_only  = false
          }
          #volume_mount {
          #  name       = "state"
          #  mount_path = "/state"
          #  read_only  = false
          #}
          volume_mount {
            name       = "config"
            mount_path = "/config"
            read_only  = true
          }
        }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.main.metadata[0].name
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "installation"
        labels = {
          "app.kubernetes.io/name"      = "moria"
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
    #volume_claim_template {
    #  metadata {
    #    name = "state"
    #    labels = {
    #      "app.kubernetes.io/name"      = "moria"
    #      "app.kubernetes.io/component" = "state"
    #    }
    #    annotations = { "reclaimspace.csiaddons.openshift.io/schedule" = "50 4 * * *" }
    #  }
    #  spec {
    #    access_modes       = ["ReadWriteOnce"]
    #    storage_class_name = "rbd-gameservers0"
    #    volume_mode        = "Filesystem"
    #    resources {
    #      requests = { storage = "32Gi" }
    #    }
    #  }
    #}
  }
}
