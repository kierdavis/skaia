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
  source       = "github.com/kierdavis/stamp?ref=5f6947b6e5cf8a5cc43abc856ac0d1e74a397f80"
  flake_output = var.flake_output
  repo         = "docker.io/${var.repo_namespace}/${var.repo_name}"
}

output "repo_tag" {
  value = module.image.repo_tag
}
