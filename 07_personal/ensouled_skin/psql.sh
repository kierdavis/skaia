#!/bin/bash
set -o errexit -o nounset -o pipefail
export pod_name=ensouled-skin-psql-$(date +%s)
overrides=$(jq --null-input --compact-output '{
  apiVersion: "v1",
  kind: "Pod",
  spec: {
    containers: [{
      name: env.pod_name,
      envFrom: [{
        secretRef: {
          name: "ensouled-skin-psql",
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
