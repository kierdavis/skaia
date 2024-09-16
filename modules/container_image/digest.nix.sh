#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

query=$(cat)
src=$(jq --raw-output .src <<<"$query")
eval args=($(jq --raw-output '.args|fromjson|to_entries|map(["--arg",.key,.value])|flatten|@sh' <<<"$query"))

generator=$(nix-build --no-out-link "${args[@]}" "$src")
jq --raw-input --compact-output '{generator:.,digest:.|ltrimstr("/nix/store/")|split("-")|.[0]}' <<<"$generator"
