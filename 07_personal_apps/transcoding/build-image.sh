#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail -o xtrace

cleanup() {
  if [[ -n "${wc:-}" ]]; then
    buildah rm "$wc"
  fi
}
trap cleanup EXIT

wc=$(buildah from docker.io/nixos/nix@sha256:fd7a5c67d396fe6bddeb9c10779d97541ab3a1b2a9d744df3754a99add4046f1)
buildah run --network=slirp4netns "$wc" -- mkdir -p /run/opengl-driver/lib/dri
buildah run --network=slirp4netns "$wc" -- sh -c 'ln -sf $(nix-build "<nixpkgs>" -A intel-media-driver --no-out-link)/lib/dri/iHD_drv_video.so /run/opengl-driver/lib/dri/iHD_drv_video.so'
buildah run --network=slirp4netns "$wc" -- nix-env --install --attr nixpkgs.ffmpeg-full --attr nixpkgs.libva-utils
buildah commit --iidfile="$iidfile" --timestamp=0 "$wc"
