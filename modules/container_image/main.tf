terraform {
  required_providers {
    dockerhub = {
      source = "BarnabyShearer/dockerhub"
    }
    external = {
      source = "hashicorp/external"
    }
  }
}

variable "repo_name" {
  type = string
}

variable "repo_namespace" {
  type = string
}

variable "builder" {
  type    = string
  default = "podman"
  validation {
    condition     = contains(["nix", "podman"], var.builder)
    error_message = "`builder` must be either \"nix\" or \"podman\""
  }
}

variable "src" {
  type = string
}

variable "args" {
  type    = map(string)
  default = {}
}

resource "dockerhub_repository" "main" {
  name      = var.repo_name
  namespace = var.repo_namespace
  private   = false
}

data "external" "build" {
  program = ["${path.module}/build.${var.builder}.sh"]
  query = {
    src  = var.src
    args = jsonencode(var.args)
  }
}

locals {
  id      = data.external.build.result.id
  id_safe = replace(local.id, ":", ".")
  tag     = "docker.io/${var.repo_namespace}/${var.repo_name}:${local.id_safe}"
}

resource "terraform_data" "tag_and_push" {
  depends_on       = [dockerhub_repository.main]
  triggers_replace = local.tag
  provisioner "local-exec" {
    command = "exec ${path.module}/tag_and_push.sh"
    environment = {
      id  = local.id
      tag = local.tag
    }
  }
}

output "id" {
  value = local.id
}

output "tag" {
  depends_on = [terraform_data.tag_and_push]
  value      = local.tag
}
