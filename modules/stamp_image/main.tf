terraform {
  required_providers {
    dockerhub = {
      source = "BarnabyShearer/dockerhub"
    }
  }
}

variable "repo_name" {
  type = string
}

variable "repo_namespace" {
  type = string
}

variable "flake" {
  type = string
}

resource "dockerhub_repository" "main" {
  name      = var.repo_name
  namespace = var.repo_namespace
  private   = false
}

module "image" {
  source             = "github.com/kierdavis/stamp?ref=d89302f420377c6bdfd342387e38e38eba1351b6"
  flake              = var.flake
  repo               = "docker.io/${var.repo_namespace}/${var.repo_name}"
  derivation_symlink = "/home/kier/.cache/skaia/stamp-drvs/${var.repo_namespace}/${var.repo_name}"
}

output "repo_tag" {
  value = module.image.repo_tag
}
