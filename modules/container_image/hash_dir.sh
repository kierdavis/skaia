#!/bin/bash

set -o errexit -o nounset -o pipefail

path=$(jq --raw-output .path)
tar --create --directory="$path" --exclude-ignore-recursive=.dockerignore --sort=name --mtime=0 --owner=root:0 --group=root:0 . \
  | sha1sum \
  | jq --raw-input --compact-output 'split(" ") | {hash: .[0]}'
