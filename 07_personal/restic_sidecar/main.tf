locals {
  globals = yamldecode(file("${path.module}/../../globals.yaml"))
}

module "image" {
  source         = "../../modules/stamp_image"
  repo_name      = "skaia-restic-sidecar"
  repo_namespace = local.globals.docker_hub.username
  flake          = "path:${path.module}/image"
}

output "image" {
  value = module.image.repo_tag
}
