#!/usr/bin/env nix-shell
#!nix-shell -p crane -i bash
set -o errexit -o nounset -o pipefail

dir=$(nix-store --realise "$derivation")
crane push --index "$dir/oci" "$name_and_tag"
