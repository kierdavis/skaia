#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail -o xtrace

query=$(cat)
src=$(jq --raw-output .src <<<"$query")
eval $(jq --raw-output '.args|fromjson|to_entries[]|"export \(.key)=\(.value|@sh)"' <<<"$query")

export iidfile=$(mktemp)
trap "rm -f $iidfile" EXIT

buildah unshare "$src" >&2

xargs podman image inspect <"$iidfile" \
  | jq --compact-output '.[0]|{iid:.Id,digest:.Digest|ltrimstr("sha256:")}'
