#!/bin/bash
set -o errexit -o nounset -o pipefail
export instance="$1"
export pod_name=redstore-"$instance"-psql-$(date +%s)
overrides=$(jq --null-input --compact-output '{
  apiVersion: "v1",
  kind: "Pod",
  spec: {
    containers: [{
      name: env.pod_name,
      envFrom: [{
        secretRef: {
          name: "redstore-\(env.instance)",
        },
      }],
    }],
  },
}')
exec kubectl \
  --namespace=personal \
  run \
  --image=docker.io/library/postgres \
  --overrides="$overrides" \
  --override-type=strategic \
  --rm \
  --stdin \
  --tty \
  "$pod_name" \
  -- \
  psql
