#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

dummy_tag_line=$(
  "$generator" \
  | podman load \
  |& tee /dev/stderr \
  | grep '^Loaded image:'
)
dummy_tag="${dummy_tag_line#Loaded image: }"
echo >&2 "dummy_tag=$dummy_tag"
iid=$(podman image inspect "$dummy_tag" | jq --raw-output '.[0].Id')
echo >&2 "iid=$iid"
podman image untag "$dummy_tag"

podman image tag "$iid" "$tag"
podman image push "$tag"
podman image untag "$tag"
