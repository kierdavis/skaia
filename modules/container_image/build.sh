#!/bin/bash
set -o errexit -o nounset -o pipefail
iidfile=$(mktemp)
trap "rm -f $iidfile" EXIT
podman build --iidfile="$iidfile" $(jq --raw-output .args) >&2
jq --raw-input --compact-output '{id:.}' "$iidfile"
