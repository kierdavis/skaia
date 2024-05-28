#!/bin/sh
set -o errexit -o nounset -o pipefail

namespace="${1:-}"
configname="${2:-}"
if [[ -z "$namespace" || -z "$configname" ]]; then
  echo >&2 "usage: $0 <namespace> <backupconfigurationname>"
  exit 1
fi

kubectl apply -f - <<EOF
apiVersion: stash.appscode.com/v1beta1
kind: BackupSession
metadata:
  name: $configname-$(date +%s)-adhoc
  namespace: $namespace
  labels:
    stash.appscode.com/invoker-type: BackupConfiguration
    stash.appscode.com/invoker-name: $configname
spec:
  invoker:
    apiGroup: stash.appscode.com
    kind: BackupConfiguration
    name: $configname
EOF
