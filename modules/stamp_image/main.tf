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
  source = "github.com/kierdavis/stamp?ref=6db482bd0bd13dad72899ebccd4b880cff0b3e5b"
  flake  = var.flake
  repo   = "docker.io/${var.repo_namespace}/${var.repo_name}"
}

output "repo_tag" {
  value = module.image.repo_tag
}
