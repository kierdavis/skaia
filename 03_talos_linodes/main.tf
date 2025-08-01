terraform {
  backend "local" {
    path = "/net/skaia/tfstate/skaia/03_talos_linodes.tfstate"
  }
  required_providers {
    linode = {
      source = "linode/linode"
    }
  }
}

locals {
  nodes = {
    # Temporary master for upgrades.
    #nitram = {
    #  type  = "g6-standard-1"
    #  image = data.terraform_remote_state.image.outputs.linode_image_id["1.10.4"]
    #}
    # Worker node.
    #zahhak = {
    #  type  = "g6-standard-2"
    #  image = data.terraform_remote_state.image.outputs.linode_image_id["1.9.5"]
    #}
  }
}

provider "linode" {
  token = var.linode_token
}

data "terraform_remote_state" "image" {
  backend = "local"
  config = {
    path = "/net/skaia/tfstate/skaia/02_talos_image.tfstate"
  }
}

resource "linode_instance" "main" {
  for_each   = local.nodes
  label      = each.key
  region     = "gb-lon"
  type       = each.value.type
  private_ip = false
}

resource "linode_instance_disk" "talos" {
  for_each  = local.nodes
  label     = "talos"
  linode_id = linode_instance.main[each.key].id
  size      = linode_instance.main[each.key].specs[0].disk
  image     = each.value.image
}

resource "linode_instance_config" "main" {
  for_each    = local.nodes
  label       = "main"
  linode_id   = linode_instance.main[each.key].id
  root_device = "/dev/sda"
  kernel      = "linode/direct-disk"
  booted      = true
  device {
    device_name = "sda"
    disk_id     = linode_instance_disk.talos[each.key].id
  }
}

resource "linode_firewall" "main" {
  for_each        = local.nodes
  label           = each.key
  linodes         = [linode_instance.main[each.key].id]
  disabled        = false
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
  inbound {
    label    = "ping"
    action   = "ACCEPT"
    protocol = "ICMP"
    ipv4     = toset(["0.0.0.0/0"])
    ipv6     = toset(["::0/0"])
  }
  #inbound {
  #  label    = "talos-init"
  #  action   = "ACCEPT"
  #  protocol = "TCP"
  #  ports    = "50000"
  #  ipv4     = var.authorized_ssh_ipv4_nets
  #  ipv6     = var.authorized_ssh_ipv6_nets
  #}
  inbound {
    label    = "tailscale"
    action   = "ACCEPT"
    protocol = "UDP"
    ports    = "41641"
    ipv4     = toset(["0.0.0.0/0"])
    ipv6     = toset(["::0/0"])
  }
}

output "ip_address" {
  value = { for name, inst in linode_instance.main : name => inst.ip_address }
}
