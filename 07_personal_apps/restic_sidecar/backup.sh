#!/bin/sh
set -o errexit -o nounset -o pipefail
exec restic backup \
  --exclude=lost+found \
  --exclude=.nobackup \
  --exclude='.Trash-*' \
  --host=generic \
  --one-file-system \
  --read-concurrency=4 \
  --tag=auto \
  "$DIR"
