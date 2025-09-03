#!/usr/bin/env nix-shell
#!nix-shell -p cargo -p go -p rustfmt -p terraform -i bash
set -o errexit -o nounset -o pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

echo >&2 "terraform fmt"
rg --files --glob '*.tf' | xargs terraform fmt
echo >&2

for x in $(rg --files --glob Cargo.toml); do
  x="$(dirname "$x")"
  echo >&2 "cargo fmt in $x"
  pushd "$x" 2>/dev/null
  cargo fmt
  popd 2>/dev/null
  echo >&2
done

for x in $(rg --files --glob go.mod); do
  x="$(dirname "$x")"
  echo >&2 "go fmt in $x"
  pushd "$x" 2>/dev/null
  go fmt .
  popd 2>/dev/null
  echo >&2
done
