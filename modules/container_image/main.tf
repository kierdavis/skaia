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

# Should be the smallest amount of work needed to obtain a hash of the src & args.
data "external" "digest" {
  program = ["${path.module}/digest.${var.builder}.sh"]
  query = {
    src  = var.src
    args = jsonencode(var.args)
  }
}

locals {
  tag = "docker.io/${var.repo_namespace}/${var.repo_name}:${data.external.digest.result.digest}"
}

resource "terraform_data" "push" {
  depends_on       = [dockerhub_repository.main]
  triggers_replace = local.tag
  provisioner "local-exec" {
    command = "exec ${path.module}/push.${var.builder}.sh"
    environment = merge(data.external.digest.result, {
      tag = local.tag
    })
  }
}

output "tag" {
  depends_on = [terraform_data.push]
  value      = local.tag
}
