terraform {
  backend "local" {
    path = "/net/skaia/tfstate/skaia/01_tailnet.tfstate"
  }
  required_providers {
    headscale = {
      source = "awlsring/headscale"
    }
  }
}

data "terraform_remote_state" "becquerel" {
  backend = "local"
  config = {
    path = "/net/skaia/tfstate/skaia/00_becquerel.tfstate"
  }
}

provider "headscale" {
  endpoint = data.terraform_remote_state.becquerel.outputs.headscale.endpoint
  api_key  = data.terraform_remote_state.becquerel.outputs.headscale.api_key
}

resource "headscale_user" "system" {
  name = "skaia"
}

resource "headscale_user" "me" {
  name = "kier"
}

resource "headscale_pre_auth_key" "workstation" {
  for_each       = toset(["coloris", "colorisw", "saelli"])
  user           = headscale_user.me.name
  acl_tags       = ["tag:hostname:${each.key}"]
  ephemeral      = false
  reusable       = false
  time_to_expire = "1h"
}

data "headscale_device" "main" {
  for_each = toset(["coloris"])
  name     = each.key
}

# If only `tailscale up --advertise-tags` worked...
resource "headscale_device_tags" "coloris" {
  device_id = data.headscale_device.main["coloris"].id
  tags      = ["tag:nix-builder"]
}

output "system_user_name" {
  value = headscale_user.system.name
}

output "workstation_pre_auth_keys" {
  value     = { for name, res in headscale_pre_auth_key.workstation : name => res.key }
  sensitive = true
}
