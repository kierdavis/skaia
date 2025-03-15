terraform {
  required_providers {
    external = {
      source = "hashicorp/external"
    }
    linode = {
      source = "linode/linode"
    }
  }
}

locals {
  globals = yamldecode(file("${path.module}/../globals.yaml"))
}

provider "linode" {
  token             = local.globals.linode.token
  obj_use_temp_keys = true
}

locals {
  instances = {
    "1.7.7" = {
      version = "1.7.7"
      schematic = {
        customization = {
          systemExtensions = {
            officialExtensions = ["siderolabs/tailscale"]
          }
        }
      }
    }
    "1.9.5" = {
      version = "1.9.5"
      schematic = {
        customization = {
          systemExtensions = {
            officialExtensions = [
              "siderolabs/i915",
              "siderolabs/tailscale",
            ]
          }
          extraKernelArgs = [
            "console=ttyS0,19200n8", # Linode
            "console=tty1",          # Bare metal
          ]
        }
      }
    }
    "1.9.5-nitram" = {
      version = "1.9.5"
      schematic = {
        customization = {
          systemExtensions = {
            officialExtensions = [
              "siderolabs/tailscale",
            ]
          }
          extraKernelArgs = [
            "console=ttyS0,19200n8", # Linode
            "console=tty1",          # Bare metal
          ]
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

output "installer_image" {
  value = {
    for key, inst in local.instances2 :
    key => "factory.talos.dev/installer/${inst.schematic_id}:v${inst.version}"
  }
}

locals {
  linode_image_path = {
    for key, inst in local.instances2 :
    key => "${path.module}/work/talos-${inst.version}-${inst.schematic_id}-linode.img.gz"
  }
}

resource "terraform_data" "convert_for_linode" {
  for_each         = local.instances2
  triggers_replace = local.linode_image_path[each.key]
  provisioner "local-exec" {
    command = <<EOF
      mkdir -p "$(dirname "$dest")"
      curl --silent --show-error --fail "$src" \
        | unxz --stdout \
        | pigz --stdout > "$dest"
    EOF
    environment = {
      src  = "https://factory.talos.dev/image/${each.value.schematic_id}/v${each.value.version}/metal-amd64.raw.xz"
      dest = local.linode_image_path[each.key]
    }
  }
}

resource "linode_image" "main" {
  for_each   = local.instances2
  label      = "skaia-talos-${each.value.version}-${each.value.schematic_id_short}"
  file_path  = local.linode_image_path[each.key]
  file_hash  = try(filemd5(local.linode_image_path[each.key]), null)
  region     = "fr-par" # Only using fr-par due to a Linode outage; go back to gb-lon next time.
  depends_on = [terraform_data.convert_for_linode]
}

output "linode_image_id" {
  value = {
    for key, inst in local.instances2 :
    key => linode_image.main[key].id
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
