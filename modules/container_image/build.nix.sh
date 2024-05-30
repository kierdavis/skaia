#!/bin/bash
set -o errexit -o nounset -o pipefail

query=$(cat)
src=$(jq --raw-output .src <<<"$query")
eval args=($(jq --raw-output '.args|fromjson|to_entries|map(["--arg",.key,.value])|flatten|@sh' <<<"$query"))

tmpdir=$(mktemp -d)
trap "rm -rf $tmpdir" EXIT
generator="$tmpdir/result"

nix-build --out-link "$generator" "${args[@]}" "$src"
"$generator" | podman load
