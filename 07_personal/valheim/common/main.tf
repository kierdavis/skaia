locals {
  globals = yamldecode(file("${path.module}/../../../globals.yaml"))
}

module "image" {
  source         = "../../../modules/stamp_image"
  repo_name      = "skaia-valheim"
  repo_namespace = local.globals.docker_hub.username
  flake_output   = "./${path.module}/../../..#personal.valheim.common.image"
}

output "image" {
  value = module.image.repo_tag
}
