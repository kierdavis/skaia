terraform {
  required_providers {
    dockerhub = {
      source = "BarnabyShearer/dockerhub"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

locals {
  ceph_version = "18.2.2"

  globals = yamldecode(file("${path.module}/../globals.yaml"))
}

provider "dockerhub" {
  username = local.globals.docker_hub.username
  password = local.globals.docker_hub.password
}

data "terraform_remote_state" "talos" {
  backend = "local"
  config = {
    path = "${path.module}/../04_talos/terraform.tfstate"
  }
}

data "terraform_remote_state" "operator" {
  backend = "local"
  config = {
    path = "${path.module}/../06_rook_ceph_operator/terraform.tfstate"
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.talos.outputs.kubernetes.host
  cluster_ca_certificate = data.terraform_remote_state.talos.outputs.kubernetes.cluster_ca_certificate
  client_certificate     = data.terraform_remote_state.talos.outputs.kubernetes.client_certificate
  client_key             = data.terraform_remote_state.talos.outputs.kubernetes.client_key
}

locals {
  namespace = data.terraform_remote_state.operator.outputs.namespace
}

#resource "kubernetes_config_map" "ceph" {
#  metadata {
#    name = "rook-config-override"
#    namespace = local.namespace
#  }
#  data = {
#    config = <<-EOF
#      [global]
#      bluestore_compression_mode = aggressive
#      osd_pool_default_size = 2
#      osd_scrub_min_interval = ${60 * 60 * 24 * 7 * 3}
#      osd_scrub_max_interval = ${60 * 60 * 24 * 7 * 5}
#    EOF
#  }
#}
