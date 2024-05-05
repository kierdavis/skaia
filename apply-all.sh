#!/bin/sh

set -o errexit -o nounset -o pipefail

for dir in [0-9][0-9]_*; do
  echo >&2
  echo >&2 "$dir"
  echo >&2
  terraform -chdir="$dir" apply
done
