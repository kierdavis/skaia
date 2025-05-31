#!/bin/sh
set -o errexit -o nounset -o pipefail

namespace="${1:-}"
name="${2:-}"
if [[ -z "$namespace" || -z "$name" ]]; then
  echo >&2 "usage: $0 <namespace> <name>"
  exit 1
fi

exec kubectl --namespace="$namespace" create job "$name-$(date +%s)-adhoc" --from="cronjob/$name"
