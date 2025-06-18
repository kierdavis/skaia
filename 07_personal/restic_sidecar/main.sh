#!/bin/sh
set -o errexit -o nounset -o pipefail

if [[ -z "${SCHEDULE:-}" ]]; then
  echo >&2 "SCHEDULE environment variable not set."
  exit 1
fi

if [[ -z "${DIR:-}" ]]; then
  echo >&2 "DIR environment variable not set."
  exit 1
fi

echo "$SCHEDULE /bin/backup.sh" > /var/spool/cron/crontabs/root
exec crond -f
