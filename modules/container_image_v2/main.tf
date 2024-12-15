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

variable "src" {
  type = string
}

#variable "args" {
#  type = map(string)
#  default = {}
#}

resource "dockerhub_repository" "main" {
  name      = var.repo_name
  namespace = var.repo_namespace
  private   = false
}

# Should be the smallest amount of work needed to obtain a hash of the src, args, and build infrastructure.
data "external" "derivation" {
  program = ["${path.module}/derivation.sh"]
  query = {
    src = var.src
    #args = jsonencode(var.args)
  }
}

locals {
  name_and_tag = "docker.io/${var.repo_namespace}/${var.repo_name}:${data.external.derivation.result.tag}"
}

resource "terraform_data" "build_and_push" {
  depends_on       = [dockerhub_repository.main]
  triggers_replace = local.name_and_tag
  provisioner "local-exec" {
    command = "exec ${path.module}/build_and_push.sh"
    environment = merge(data.external.derivation.result, {
      name_and_tag = local.name_and_tag
    })
  }
}

output "name_and_tag" {
  depends_on = [terraform_data.build_and_push]
  value      = local.name_and_tag
}

