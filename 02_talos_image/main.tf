terraform {
  backend "local" {
    path = "/net/skaia/tfstate/skaia/02_talos_image.tfstate"
  }
  required_providers {
    external = {
      source = "hashicorp/external"
    }
    linode = {
      source = "linode/linode"
    }
  }
}

provider "linode" {
  token             = var.linode_token
  obj_use_temp_keys = true
}

locals {
  instances = {
    "1.10.4" = {
      platforms = toset(["linode", "pc"])
      version   = "1.10.4"
      schematic = {
        customization = {
          systemExtensions = {
            officialExtensions = [
              "siderolabs/i915",
              "siderolabs/tailscale",
            ]
          }
          extraKernelArgs = [
            "-console",              # Remove any console= arguments from the default command line.
            "console=ttyS0,19200n8", # Linode
            "console=tty1",          # Bare metal
          ]
        }
      }
    }
    "1.10.4-rpi" = {
      platforms = toset(["rpi"])
      version   = "1.10.4"
      schematic = {
        customization = {
          systemExtensions = {
            officialExtensions = [
              "siderolabs/tailscale",
            ]
          }
          extraKernelArgs = [
            "-console",               # Remove any console= arguments from the default command line.
            "console=serial0,115200", # Raspberry Pi UART
            "console=tty1",           # Raspberry Pi HDMI
          ]
        }
        overlay = {
          image = "siderolabs/sbc-raspberrypi"
          name  = "rpi_generic"
          options = {
            configTxtAppend = <<-EOT
              enable_uart=1
              uart_2ndstage=1
            EOT
          }
        }
      }
    }
  }
}

data "external" "schematic_id" {
  for_each = local.instances
  program  = ["sh", "-c", "jq -r .yaml | curl --silent --show-error --fail --data-binary @- https://factory.talos.dev/schematics"]
  query    = { yaml = yamlencode(each.value.schematic) }
}

locals {
  instances2 = {
    for key, inst in local.instances :
    key => merge(inst, {
      schematic_id       = data.external.schematic_id[key].result.id
      schematic_id_short = substr(data.external.schematic_id[key].result.id, 0, 8)
    })
  }
}

locals {
  linode_image_path = {
    for key, inst in local.instances2 :
    key => "${path.module}/work/talos-${inst.version}-${inst.schematic_id}-linode.img.gz"
    if contains(inst.platforms, "linode")
  }
}

resource "terraform_data" "convert_for_linode" {
  for_each         = local.linode_image_path
  triggers_replace = each.value
  provisioner "local-exec" {
    command = <<EOF
      mkdir -p "$(dirname "$dest")"
      curl --silent --show-error --fail "$src" \
        | unxz --stdout \
        | pigz --stdout > "$dest"
    EOF
    environment = {
      src  = "https://factory.talos.dev/image/${local.instances2[each.key].schematic_id}/v${local.instances2[each.key].version}/metal-amd64.raw.xz"
      dest = each.value
    }
  }
}

resource "linode_image" "main" {
  for_each   = terraform_data.convert_for_linode
  label      = "skaia-talos-${local.instances2[each.key].version}-${local.instances2[each.key].schematic_id_short}"
  file_path  = local.linode_image_path[each.key]
  file_hash  = try(filemd5(local.linode_image_path[each.key]), null)
  region     = "fr-par" # Only using fr-par due to a Linode outage; go back to gb-lon next time.
  depends_on = [terraform_data.convert_for_linode]
}

output "linode_image_id" {
  value = {
    for key, lin_img in linode_image.main :
    key => lin_img.id
  }
}

resource "linode_object_storage_bucket" "bare_metal" {
  region     = "fr-par"
  label      = "skaia-talos-image"
  acl        = "private"
  versioning = false
}

resource "linode_object_storage_object" "bare_metal" {
  bucket       = linode_object_storage_bucket.bare_metal.label
  region       = linode_object_storage_bucket.bare_metal.region
  key          = "install.py"
  acl          = "public-read"
  content_type = "text/x-python"
  content      = templatefile("install.py", { flavours = local.instances2 })
}

output "bare_metal_script_url" {
  value = "https://${linode_object_storage_object.bare_metal.bucket}.${linode_object_storage_object.bare_metal.endpoint}/${linode_object_storage_object.bare_metal.key}"
}

output "rpi_image" {
  value = {
    for key, inst in local.instances2 :
    key => "https://factory.talos.dev/image/${inst.schematic_id}/v${inst.version}/metal-arm64.raw.xz"
    if contains(inst.platforms, "rpi")
  }
}
