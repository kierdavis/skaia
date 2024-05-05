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

variable "args" {
  type    = map(string)
  default = {}
}

data "external" "src_hash" {
  program = ["${path.module}/hash_dir.sh"]
  query   = { path = var.src }
}

locals {
  input_hash = sha1(jsonencode({
    src  = data.external.src_hash.result.hash
    args = var.args
  }))
  tag = "docker.io/${var.repo_namespace}/${var.repo_name}:${local.input_hash}"
}

resource "dockerhub_repository" "main" {
  name      = var.repo_name
  namespace = var.repo_namespace
  private   = false
}

resource "terraform_data" "build_and_push" {
  depends_on       = [dockerhub_repository.main]
  triggers_replace = local.tag
  provisioner "local-exec" {
    command = "exec ${path.module}/build_and_push.sh"
    environment = {
      src  = var.src
      tag  = local.tag
      args = join(" ", [for name, value in var.args : "--build-arg=${name}=${value}"])
    }
  }
}

output "tag" {
  depends_on = [terraform_data.build_and_push]
  value      = local.tag
}
