#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

module_dir="$(dirname "${BASH_SOURCE[0]}")"

query=$(cat)
src=$(jq --raw-output .src <<<"$query")
#eval args=($(jq --raw-output '.args|fromjson|to_entries|map(["--arg",.key,.value])|flatten|@sh' <<<"$query"))

derivation=$(nix-instantiate -I src="$src" "$module_dir/image.nix")
jq --raw-input --compact-output '{derivation:.,tag:.|ltrimstr("/nix/store/")|split("-")|.[0]}' <<<"$derivation"
