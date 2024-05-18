#!/bin/bash
set -o errexit -o nounset -o pipefail

podman tag "$id" "$tag"
podman push "$tag"
