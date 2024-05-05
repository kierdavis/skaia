terraform {
  required_providers {
    headscale = {
      source = "awlsring/headscale"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.5"
    }
  }
}

locals {
  api_contract_version = "1.6"

  nodes = {
    vantas = {
      role                     = "controlplane"
      boot_disk                = "/dev/nvme0n1"
      bootstrap_endpoint       = "192.168.178.154"
      force_bootstrap_endpoint = false # set to true if tailscaled is broken
      labels = {
        "topology.kubernetes.io/region" = "r-man"
        "topology.kubernetes.io/zone"   = "z-adw"
        "topology.rook.io/chassis"      = "c-vantas"
      }
    }
    pyrope = {
      role                     = "controlplane"
      boot_disk                = "/dev/nvme0n1"
      bootstrap_endpoint       = "192.168.178.164"
      force_bootstrap_endpoint = false # set to true if tailscaled is broken
      labels = {
        "topology.kubernetes.io/region" = "r-man"
        "topology.kubernetes.io/zone"   = "z-adw"
        "topology.rook.io/chassis"      = "c-pyrope"
      }
    }
    peixes = {
      role                     = "controlplane"
      boot_disk                = "/dev/sda"
      bootstrap_endpoint       = "peixes.skaia.cloud"
      force_bootstrap_endpoint = false # set to true if tailscaled is broken
      labels = {
        "topology.kubernetes.io/region" = "r-lon"
        "topology.kubernetes.io/zone"   = "z-linode-eu-west"
        "topology.rook.io/chassis"      = "c-peixes"
      }
    }
  }
  arbitrary_node = "vantas"

  globals = yamldecode(file("${path.module}/../globals.yaml"))
}

data "terraform_remote_state" "becquerel" {
  backend = "local"
  config = {
    path = "${path.module}/../00_becquerel/terraform.tfstate"
  }
}

data "terraform_remote_state" "tailnet" {
  backend = "local"
  config = {
    path = "${path.module}/../01_tailnet/terraform.tfstate"
  }
}

provider "headscale" {
  endpoint = data.terraform_remote_state.becquerel.outputs.headscale.endpoint
  api_key  = data.terraform_remote_state.becquerel.outputs.headscale.api_key
}

resource "headscale_pre_auth_key" "main" {
  for_each       = local.nodes
  user           = data.terraform_remote_state.tailnet.outputs.system_user_name
  acl_tags       = ["tag:hostname:${each.key}"]
  ephemeral      = false
  reusable       = false
  time_to_expire = "1h"
}

data "headscale_devices" "all" {
  user = data.terraform_remote_state.tailnet.outputs.system_user_name
}

locals {
  headscale_devices = {
    for dev in(
      data.headscale_devices.all.devices != null
      ? data.headscale_devices.all.devices
      : []
    ) :
    dev.given_name => dev
    if contains(keys(local.nodes), dev.given_name) && (timecmp(dev.expiry, plantimestamp()) > 0 || startswith(dev.expiry, "0001"))
  }
  node_endpoints = {
    for name, info in local.nodes :
    name => (
      info.force_bootstrap_endpoint
      ? info.bootstrap_endpoint
      : try(local.headscale_devices[name].addresses[0], info.bootstrap_endpoint)
    )
  }
}

resource "talos_machine_secrets" "main" {
  talos_version = "v${local.api_contract_version}"
}

data "talos_machine_configuration" "main" {
  for_each         = local.nodes
  cluster_endpoint = "https://kubeapi.skaia.cloud:6443"
  cluster_name     = "skaia"
  machine_secrets  = talos_machine_secrets.main.machine_secrets
  machine_type     = each.value.role
  talos_version    = "v${local.api_contract_version}"
  config_patches = [
    yamlencode({
      cluster = {
        allowSchedulingOnControlPlanes = true
        apiServer = {
          certSANs                 = ["kubeapi.skaia.cloud"]
          disablePodSecurityPolicy = true
        }
        controllerManager = {
          extraArgs = {
            "node-cidr-mask-size-ipv4" = local.globals.kubernetes.pod_net.node_prefix_len.ipv4
            "node-cidr-mask-size-ipv6" = local.globals.kubernetes.pod_net.node_prefix_len.ipv6
          }
        }
        discovery = { enabled = false }
        etcd = {
          advertisedSubnets = [local.globals.headscale.net.ipv4, local.globals.headscale.net.ipv6]
          listenSubnets     = [local.globals.headscale.net.ipv4, local.globals.headscale.net.ipv6]
        }
        network = {
          cni            = { name = "none" }
          dnsDomain      = "kube.skaia.cloud"
          podSubnets     = [local.globals.kubernetes.pod_net.ipv4, local.globals.kubernetes.pod_net.ipv6]
          serviceSubnets = [local.globals.kubernetes.svc_net.ipv4, local.globals.kubernetes.svc_net.ipv6]
        }
        proxy = {
          disabled = false
        }
      }
      machine = {
        certSANs = [each.key, "${each.key}.skaia.cloud"]
        features = {
          kubernetesTalosAPIAccess = {
            enabled                     = true
            allowedRoles                = ["os:admin"]
            allowedKubernetesNamespaces = ["system"]
          }
          rbac = true
        }
        kubelet = {
          nodeIP = {
            validSubnets = [local.globals.headscale.net.ipv4, local.globals.headscale.net.ipv6]
          }
        }
        install = {
          disk = each.value.boot_disk
          wipe = false
        }
        network = {
          hostname = each.key
          extraHostEntries = [
            for node_name, endpoint in local.node_endpoints :
            { ip = endpoint, aliases = [node_name, "${node_name}.skaia.cloud", "kubeapi.skaia.cloud"] }
          ]
          nameservers = ["1.1.1.1", "1.0.0.1"]
        }
        nodeLabels = each.value.labels
        sysctls = {
          "net.ipv4.ip_forward"          = "1"
          "net.ipv6.conf.all.forwarding" = "1"
        }
      }
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "ExtensionServiceConfig"
      name       = "tailscale"
      environment = [
        "TS_AUTHKEY=${headscale_pre_auth_key.main[each.key].key}",
        "TS_EXTRA_ARGS=--accept-routes --login-server=${data.terraform_remote_state.becquerel.outputs.headscale.endpoint} --netfilter-mode=off",
        "TS_HOSTNAME=${each.key}",
        "TS_USERSPACE=false",
      ]
    }),
  ]
}

resource "talos_machine_configuration_apply" "main" {
  for_each                    = local.nodes
  client_configuration        = talos_machine_secrets.main.client_configuration
  machine_configuration_input = data.talos_machine_configuration.main[each.key].machine_configuration
  node                        = each.key
  endpoint                    = local.node_endpoints[each.key]
}

resource "talos_machine_bootstrap" "main" {
  client_configuration = talos_machine_secrets.main.client_configuration
  node                 = local.arbitrary_node
  endpoint             = local.node_endpoints[local.arbitrary_node]
  depends_on           = [talos_machine_configuration_apply.main]
}

data "talos_client_configuration" "main" {
  cluster_name         = "skaia"
  client_configuration = talos_machine_secrets.main.client_configuration
  nodes                = keys(local.nodes)
  endpoints            = values(local.node_endpoints)
}

data "talos_cluster_kubeconfig" "main" {
  client_configuration = talos_machine_secrets.main.client_configuration
  node                 = local.arbitrary_node
  endpoint             = local.node_endpoints[local.arbitrary_node]
  timeouts             = { read = "5s" }
  depends_on           = [talos_machine_bootstrap.main]
}

output "talosconfig" {
  value     = data.talos_client_configuration.main.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = data.talos_cluster_kubeconfig.main.kubeconfig_raw
  sensitive = true
}

output "kubernetes" {
  value = {
    host                   = "https://${local.node_endpoints[local.arbitrary_node]}:6443"
    cluster_ca_certificate = base64decode(data.talos_cluster_kubeconfig.main.kubernetes_client_configuration.ca_certificate)
    client_certificate     = base64decode(data.talos_cluster_kubeconfig.main.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(data.talos_cluster_kubeconfig.main.kubernetes_client_configuration.client_key)
  }
  sensitive = true
}

output "node_endpoints" {
  value = local.node_endpoints
}
