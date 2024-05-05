#!/bin/bash

set -o errexit -o nounset -o pipefail

# N.B. --squash totally defeats layer reuse during build.
podman build $args --tag="$tag" "$src"
podman push "$tag"
