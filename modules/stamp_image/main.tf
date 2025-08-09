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

variable "flake_output" {
  type = string
}

resource "dockerhub_repository" "main" {
  name      = var.repo_name
  namespace = var.repo_namespace
  private   = false
}

module "image" {
  source       = "github.com/kierdavis/stamp?ref=c2607f69832b86ee13bc54ab0c54c3d32347589e"
  flake_output = var.flake_output
  repo         = "docker.io/${var.repo_namespace}/${var.repo_name}"
}

output "repo_tag" {
  value = module.image.repo_tag
}
