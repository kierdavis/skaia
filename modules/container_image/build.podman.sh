#!/bin/bash
set -o errexit -o nounset -o pipefail

query=$(cat)
src=$(jq --raw-output .src <<<"$query")
eval args=($(jq --raw-output '.args|fromjson|to_entries|map("--build-arg=\(.key)=\(.value)")|@sh' <<<"$query"))

iidfile=$(mktemp)
trap "rm -f $iidfile" EXIT

podman build --iidfile="$iidfile" "${args[@]}" "$src" >&2
jq --raw-input --compact-output '{id:.}' "$iidfile"
