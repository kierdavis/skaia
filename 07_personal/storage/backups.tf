module "media_backup" {
  source     = "../backup/direct_cron_job"
  name       = "media-backup"
  namespace  = var.namespace
  schedule   = "0 2 * * 2"
  pvc_name   = kubernetes_persistent_volume_claim.video.metadata[0].name
  mount_path = "/data/media"
  common     = var.backup
}

module "books_backup" {
  source     = "../backup/direct_cron_job"
  name       = "books-backup"
  namespace  = var.namespace
  schedule   = "0 2 * * 6"
  pvc_name   = kubernetes_persistent_volume_claim.books.metadata[0].name
  mount_path = "/data/books"
  common     = var.backup
}

module "photography_backup" {
  source     = "../backup/direct_cron_job"
  name       = "photography-backup"
  namespace  = var.namespace
  schedule   = "0 2 * * *"
  pvc_name   = kubernetes_persistent_volume_claim.photography.metadata[0].name
  mount_path = "/data/photography"
  common     = var.backup
}

module "projects_backup" {
  source     = "../backup/direct_cron_job"
  name       = "projects-backup"
  namespace  = var.namespace
  schedule   = "0 2 * * *"
  pvc_name   = kubernetes_persistent_volume_claim.projects.metadata[0].name
  mount_path = "/data/projects"
  common     = var.backup
}

module "documents_backup" {
  source     = "../backup/direct_cron_job"
  name       = "documents-backup"
  namespace  = var.namespace
  schedule   = "0 2 * * 4"
  pvc_name   = kubernetes_persistent_volume_claim.documents.metadata[0].name
  mount_path = "/data/documents"
  common     = var.backup
}

module "tfstate_backup" {
  source     = "../backup/direct_cron_job"
  name       = "tfstate-backup"
  namespace  = var.namespace
  schedule   = "0 2 * * *"
  pvc_name   = kubernetes_persistent_volume_claim.tfstate.metadata[0].name
  mount_path = "/data/services/tfstate"
  common     = var.backup
}
