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
  version = "1.7.7"
  schematic = {
    customization = {
      systemExtensions = {
        officialExtensions = ["siderolabs/tailscale"]
      }
    }
  }
}

data "external" "schematic_id" {
  program = ["sh", "-c", "jq -r .yaml | curl --silent --show-error --fail --data-binary @- https://factory.talos.dev/schematics"]
  query   = { yaml = yamlencode(local.schematic) }
}

locals {
  schematic_id       = data.external.schematic_id.result.id
  schematic_id_short = substr(local.schematic_id, 0, 8)
}

output "schematic_id" {
  value = local.schematic_id
}

#locals {
#  linode_image_path = "${path.module}/work/talos-${local.version}-${local.schematic_id}-linode.img.gz"
#}

#resource "terraform_data" "convert_for_linode" {
#  triggers_replace = local.linode_image_path
#  provisioner "local-exec" {
#    command = <<EOF
#      mkdir -p "$(dirname "$dest")"
#      curl --silent --show-error --fail "$src" \
#        | unxz --stdout \
#        | pigz --stdout > "$dest"
#    EOF
#    environment = {
#      src  = "https://factory.talos.dev/image/${local.schematic_id}/v${local.version}/metal-amd64.raw.xz"
#      dest = local.linode_image_path
#    }
#  }
#}

#resource "linode_image" "main" {
#  label      = "skaia-talos-${local.version}-${local.schematic_id_short}"
#  file_path  = local.linode_image_path
#  region     = "gb-lon"
#  depends_on = [terraform_data.convert_for_linode]
#}

#output "linode_image_id" {
#  value = linode_image.main.id
#}

resource "linode_object_storage_bucket" "bare_metal" {
  cluster    = "fr-par-1"
  label      = "skaia-talos-image"
  acl        = "private"
  versioning = false
}

resource "linode_object_storage_object" "bare_metal" {
  bucket       = linode_object_storage_bucket.bare_metal.label
  cluster      = linode_object_storage_bucket.bare_metal.cluster
  key          = "install.sh"
  acl          = "public-read"
  content_type = "application/x-sh"
  content      = <<-EOF
    #!/bin/bash
    set -o errexit -o nounset -o pipefail -o xtrace

    target="$1"

    if ! type jq &>/dev/null; then
      nix-env -iA nixos.jq
    fi

    wipefs --all "$target"?* || true
    wipefs --all "$target"* || true
    blkdiscard --force "$target" || true

    url="https://factory.talos.dev/image/${local.schematic_id}/v${local.version}/metal-amd64.raw.xz"
    curl --silent --show-error --fail --location "$url" \
      | xzcat | dd of="$target"

    echo fix | parted ---pretend-input-tty "$target" print

    sector_size=512
    align=4  # align partition boundaries to a multiple of this many sectors

    disk_size_s=$(parted "$target" unit s print --json | jq --raw-output .disk.size)
    disk_size=$${disk_size_s%s}
    # Last 33 sectors are reserved for the partition table mirror.
    last_part_end=$(( disk_size - 33 ))
    last_part_end=$(( (last_part_end/align)*align ))

    part6_start_s=$(parted "$target" unit s print --json | jq --raw-output '.disk.partitions[]|select(.number==6)|.start')
    part6_start=$${part6_start_s%s}
    part6_end=$(( part6_start + 50*1024*1024*1024/sector_size ))
    part6_end=$(( (part6_end/align)*align ))
    if [[ $part6_end -lt $last_part_end ]]; then
      parted "$target" mkpart OSD0 "$part6_end"s "$((last_part_end-1))"s
      parted "$target" type 7 4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D
    else
      part6_end=$last_part_end
    fi
    parted "$target" resizepart 6 "$((part6_end-1))"s

    parted "$target" print
    blkid "$target"* | sort

    echo ok
  EOF
}

output "bare_metal_script_url" {
  value = "https://${linode_object_storage_object.bare_metal.bucket}.${linode_object_storage_object.bare_metal.cluster}.linodeobjects.com/${linode_object_storage_object.bare_metal.key}"
}
