resource "kubernetes_secret" "archive" {
  metadata {
    name      = "archive"
    namespace = var.namespace
  }
  data = {
    B2_ACCOUNT_ID   = local.globals.b2.account_id
    B2_ACCOUNT_KEY  = local.globals.b2.account_key
    RESTIC_PASSWORD = local.globals.b2.archive.restic_password
  }
}

module "media_backup" {
  source              = "../restic_cron_job"
  name                = "media-backup"
  namespace           = var.namespace
  schedule            = "0 2 * * 2"
  pvc_name            = kubernetes_persistent_volume_claim.video.metadata[0].name
  mount_path          = "/data/media"
  archive_secret_name = kubernetes_secret.archive.metadata[0].name
}

module "projects_backup" {
  source              = "../restic_cron_job"
  name                = "projects-backup"
  namespace           = var.namespace
  schedule            = "0 2 * * *"
  pvc_name            = kubernetes_persistent_volume_claim.projects.metadata[0].name
  mount_path          = "/data/projects"
  archive_secret_name = kubernetes_secret.archive.metadata[0].name
}

module "documents_backup" {
  source              = "../restic_cron_job"
  name                = "documents-backup"
  namespace           = var.namespace
  schedule            = "0 2 * * 4"
  pvc_name            = kubernetes_persistent_volume_claim.documents.metadata[0].name
  mount_path          = "/data/documents"
  archive_secret_name = kubernetes_secret.archive.metadata[0].name
}

module "tfstate_backup" {
  source              = "../restic_cron_job"
  name                = "tfstate-backup"
  namespace           = var.namespace
  schedule            = "0 2 * * *"
  pvc_name            = kubernetes_persistent_volume_claim.tfstate.metadata[0].name
  mount_path          = "/data/services/tfstate"
  archive_secret_name = kubernetes_secret.archive.metadata[0].name
}

#resource "kubernetes_job" "restic_init" {
#  metadata {
#    name = "restic-init"
#    namespace = var.namespace
#    labels = { "app.kubernetes.io/name" = "restic-init" }
#  }
#  spec {
#    backoff_limit = 0
#    template {
#      metadata {
#        labels = { "app.kubernetes.io/name" = "restic-init" }
#      }
#      spec {
#        restart_policy = "Never"
#        container {
#          name = "main"
#          image = "docker.io/restic/restic@sha256:157243d77bc38be75a7b62b0c00453683251310eca414b9389ae3d49ea426c16"
#          args = [
#            "init",
#            "--repo=b2:${local.globals.b2.archive.bucket}:/skaia/personal-1",
#          ]
#          env_from {
#            secret_ref {
#              name = kubernetes_secret.archive.metadata[0].name
#            }
#          }
#        }
#      }
#    }
#  }
#}
