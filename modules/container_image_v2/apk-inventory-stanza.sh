#!/bin/sh
set -o errexit -o nounset -o pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

image=$(nix --extra-experimental-features nix-command eval --impure --raw --expr '
  with (import <nixpkgs> { overlays = [(import ./overlay.nix)]; }).imageTools.bases.alpine;
  imageName + "@" + imageDigest
')

for name in "$@"; do

url=$(podman run --rm "$image" sh -c "apk update >&2 && apk fetch --url '$name'")
hash=$(nix-prefetch-url "$url")
cat <<EOF
  $name = fetchurl {
    url = "$url";
    hash = "sha256:$hash";
  };
EOF

done
