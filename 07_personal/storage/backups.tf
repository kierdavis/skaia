module "media_backup" {
  source              = "../restic_cron_job"
  name                = "media-backup"
  namespace           = var.namespace
  schedule            = "0 2 * * 2"
  pvc_name            = kubernetes_persistent_volume_claim.video.metadata[0].name
  mount_path          = "/data/media"
  archive_secret_name = var.archive_secret_name
}

module "photography_backup" {
  source              = "../restic_cron_job"
  name                = "photography-backup"
  namespace           = var.namespace
  schedule            = "0 2 * * *"
  pvc_name            = kubernetes_persistent_volume_claim.photography.metadata[0].name
  mount_path          = "/data/photography"
  archive_secret_name = var.archive_secret_name
}

module "projects_backup" {
  source              = "../restic_cron_job"
  name                = "projects-backup"
  namespace           = var.namespace
  schedule            = "0 2 * * *"
  pvc_name            = kubernetes_persistent_volume_claim.projects.metadata[0].name
  mount_path          = "/data/projects"
  archive_secret_name = var.archive_secret_name
}

module "documents_backup" {
  source              = "../restic_cron_job"
  name                = "documents-backup"
  namespace           = var.namespace
  schedule            = "0 2 * * 4"
  pvc_name            = kubernetes_persistent_volume_claim.documents.metadata[0].name
  mount_path          = "/data/documents"
  archive_secret_name = var.archive_secret_name
}

module "tfstate_backup" {
  source              = "../restic_cron_job"
  name                = "tfstate-backup"
  namespace           = var.namespace
  schedule            = "0 2 * * *"
  pvc_name            = kubernetes_persistent_volume_claim.tfstate.metadata[0].name
  mount_path          = "/data/services/tfstate"
  archive_secret_name = var.archive_secret_name
}
