terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    linode = {
      source = "linode/linode"
    }
  }
}

locals {
  globals = yamldecode(file("${path.module}/../globals.yaml"))
}

provider "cloudflare" {
  api_token = local.globals.cloudflare.token
}

provider "linode" {
  token = local.globals.linode.token
}

data "terraform_remote_state" "image" {
  backend = "local"
  config = {
    path = "${path.module}/../02_talos_image/terraform.tfstate"
  }
}

resource "linode_instance" "main" {
  for_each   = toset([])
  label      = each.key
  region     = "gb-lon"
  type       = "g6-standard-2"
  private_ip = false
}

resource "linode_instance_disk" "talos" {
  for_each  = linode_instance.main
  label     = "talos"
  linode_id = each.value.id
  size      = 25 * 1024 # MiB
  image     = data.terraform_remote_state.image.outputs.linode_image_id
}

resource "linode_instance_config" "main" {
  for_each    = linode_instance.main
  label       = "main"
  linode_id   = each.value.id
  root_device = "/dev/sda"
  kernel      = "linode/direct-disk"
  booted      = true
  device {
    device_name = "sda"
    disk_id     = linode_instance_disk.talos[each.key].id
  }
}

resource "linode_firewall" "main" {
  for_each        = linode_instance.main
  label           = each.key
  linodes         = [each.value.id]
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
  #  ipv4     = toset(local.globals.authorized_ssh.nets.ipv4)
  #  ipv6     = toset(local.globals.authorized_ssh.nets.ipv6)
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

resource "cloudflare_record" "main" {
  for_each = linode_instance.main
  zone_id  = local.globals.cloudflare.zone_id
  name     = each.key
  type     = "A"
  value    = each.value.ip_address
  proxied  = false
}
