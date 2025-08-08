terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

variable "config_map_name" {
  type = string
}

variable "config_map_namespace" {
  type = string
}

variable "config_map_labels" {
  type = map(string)
}

variable "flake_output" {
  type = string
}

module "realisation" {
  source       = "github.com/kierdavis/nix-realisation?ref=c031a4c46e77b68b3e19a8cd640908f844673bfb"
  flake_output = var.flake_output
}

data "local_file" "main" {
  filename = module.realisation.outputs.out
}

resource "kubernetes_config_map" "main" {
  metadata {
    name      = var.config_map_name
    namespace = var.config_map_namespace
    labels    = merge(var.config_map_labels, { "grafana_dashboard" = "1" })
  }
  data = {
    "${var.config_map_namespace}-${var.config_map_name}.json" = data.local_file.main.content
  }
}
