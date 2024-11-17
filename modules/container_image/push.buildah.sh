#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

podman image tag "$iid" "$tag"
podman image push "$tag"
podman image untag "$tag"
