#!/bin/sh
set -o errexit -o nounset -o pipefail

namespace="${1:-}"
name="${2:-}"
if [[ -z "$namespace" || -z "$name" ]]; then
  echo >&2 "usage: $0 <namespace> <name>"
  exit 1
fi

kubectl --namespace="$namespace" get cronjob "$name" --output=json \
  | jq --compact-output '.spec.jobTemplate * {
    apiVersion: "batch/v1",
    kind: "Job",
    metadata: {
      name: "\(.metadata.name)-\(now|round)-adhoc",
      namespace: .metadata.namespace,
    },
  }' \
  | kubectl apply -f -
