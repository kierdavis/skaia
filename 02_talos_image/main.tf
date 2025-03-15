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
            officialExtensions = ["siderolabs/tailscale"]
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
  for_each     = local.instances2
  bucket       = linode_object_storage_bucket.bare_metal.label
  region       = linode_object_storage_bucket.bare_metal.region
  key          = "install/${each.key}.sh"
  acl          = "public-read"
  content_type = "application/x-sh"
  content      = <<-EOF
    #!/bin/bash
    set -o errexit -o nounset -o pipefail -o xtrace

    target="$1"

    if ! type jq &>/dev/null; then
      nix-env -iA nixos.jq
    fi

    url="https://factory.talos.dev/image/${each.value.schematic_id}/v${each.value.version}/metal-amd64.raw.xz"

    sector_size=512
    align=4  # align partition boundaries to a multiple of this many sectors

    disk_size_s=$(parted "$target" unit s print --json | jq --raw-output .disk.size)
    disk_size=$${disk_size_s%s}
    # Last 33 sectors are reserved for the partition table mirror.
    last_part_end=$(( disk_size - 33 ))
    last_part_end=$(( (last_part_end/align)*align ))

    # TODO: THIS CONDITIONAL DOESNT WORK - FIND OUT WHY
    # TODO: THIS CONDITIONAL DOESNT WORK - FIND OUT WHY
    # TODO: THIS CONDITIONAL DOESNT WORK - FIND OUT WHY
    # TODO: THIS CONDITIONAL DOESNT WORK - FIND OUT WHY
    # TODO: THIS CONDITIONAL DOESNT WORK - FIND OUT WHY
    # TODO: THIS CONDITIONAL DOESNT WORK - FIND OUT WHY
    #if [[ -e /dev/disk/by-partlabel/OSD* ]]; then
    if false; then
      # TODO: rewrite this code to support Talos 1.9 part layout (only 4 parts at image time)
      for i in $(seq 1 5); do
        wipefs --all "$target"p"$i" || true
        blkdiscard --force "$target"p"$i" || true
      done

      part7_start_s=$(parted "$target" unit s print --json | jq --raw-output '.disk.partitions[]|select(.number==7)|.start')
      part7_start=$${part7_start_s%s}

      curl --silent --show-error --fail --location "$url" \
        | xzcat | dd of="$target" bs="$sector_size" count="$part7_start"

      echo fix | parted ---pretend-input-tty "$target" print

      part6_start_s=$(parted "$target" unit s print --json | jq --raw-output '.disk.partitions[]|select(.number==6)|.start')
      part6_start=$${part6_start_s%s}
      part6_end=$(( part6_start + 50*1024*1024*1024/sector_size ))
      part6_end=$(( (part6_end/align)*align ))
      if [[ $part6_end -gt $part7_start ]]; then
        part6_end=$part7_start
      fi
      parted "$target" resizepart 6 "$((part6_end-1))"s

      parted "$target" mkpart OSD0 "$part7_start"s "$((last_part_end-1))"s
      parted "$target" type 7 4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D

    else
      wipefs --all "$target"?* || true
      wipefs --all "$target"* || true
      blkdiscard --force "$target" || true

      curl --silent --show-error --fail --location "$url" \
        | xzcat | dd of="$target"

      echo fix | parted ---pretend-input-tty "$target" print

      part4_end_s=$(parted "$target" unit s print --json | jq --raw-output '.disk.partitions[]|select(.number==4)|.end')
      part4_end=$(( $${part4_end_s%s} + 1 ))
      unalloc_start=$part4_end
      unalloc_start=$(( ((unalloc_start+align-1)/align)*align ))
      unalloc_end=$(( unalloc_start + 50*1024*1024*1024/sector_size ))
      unalloc_end=$(( (unalloc_end/align)*align ))

      if [[ $unalloc_end -lt $last_part_end ]]; then
        parted "$target" mkpart OSD0 "$unalloc_end"s "$((last_part_end-1))"s
        parted "$target" type 5 4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D
      else
        unalloc_end=$last_part_end
      fi
    fi

    parted "$target" print
    blkid "$target"* | sort
    echo ok
  EOF
}

output "bare_metal_script_url" {
  value = {
    for key, obj in linode_object_storage_object.bare_metal :
    key => "https://${obj.bucket}.${obj.endpoint}/${obj.key}"
  }
}
