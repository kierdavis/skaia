resource "kubernetes_secret" "archive" {
  metadata {
    name      = "archive"
    namespace = "system"
  }
  data = {
    B2_ACCOUNT_ID     = var.b2_account_id
    B2_ACCOUNT_KEY    = var.b2_account_key
    RESTIC_REPOSITORY = "b2:${var.b2_archive_bucket}:personal-restic"
    RESTIC_PASSWORD   = var.b2_archive_restic_password
  }
}
