locals {
  globals = yamldecode(file("${path.module}/../../../globals.yaml"))
}

module "image" {
  source         = "../../../modules/container_image_v2"
  repo_name      = "skaia-valheim"
  repo_namespace = local.globals.docker_hub.username
  src            = "${path.module}/image.nix"
}

output "image" {
  value = module.image.name_and_tag
}
