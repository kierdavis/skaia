resource "kubernetes_cron_job_v1" "ageout" {
  metadata {
    name      = "backup-ageout"
    namespace = var.namespace
    labels    = { "app.kubernetes.io/name" = "backup-ageout" }
  }
  spec {
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 1
    schedule                      = "0 3 * * *"
    starting_deadline_seconds     = 6 * 60 * 60
    successful_jobs_history_limit = 1
    job_template {
      metadata {
        labels = { "app.kubernetes.io/name" = "backup-ageout" }
      }
      spec {
        backoff_limit = 0
        template {
          metadata {
            labels = { "app.kubernetes.io/name" = "backup-ageout" }
          }
          spec {
            restart_policy = "Never"
            container {
              name  = "main"
              image = module.image.repo_tag
              args  = ["ageout", "--force"]
              env_from {
                secret_ref {
                  name = kubernetes_secret.archive.metadata[0].name
                }
              }
            }
          }
        }
      }
    }
  }
}

