{ callPackage, dumb-init, fetchzip, generatedCargoNix, iproute2, lib, nftables, stamp, tailscale }:

let
  # Talos Linux includes some plugins, but not all. We need 'ptp'.
  # Can't use cni-plugins from nixpkgs because its binaries contain references to other store paths.
  # We need 100% statically-linked binaries here.
  cniPlugins = fetchzip {
    name = "plugins";
    url = "https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz";
    hash = "sha256-YiWYXWzWh3iLMztTUNALcoXJNq+uEhXkInQhkuzrfVI=";
    stripRoot = false;
    postFetch = ''
      mkdir $out/.keep
      mv $out/ptp $out/.keep
      rm $out/*
      mv $out/.keep/* $out
      rmdir $out/.keep
    '';
  };
  cargoNix = generatedCargoNix {
    name = "skaia-cni";
    src = builtins.filterSource (path: type: baseNameOf path != "target") ./crate;
  };
  app = (callPackage cargoNix {}).rootCrate.build;
in stamp.fromNix {
  name = "stamp-img-skaia-cni";
  entrypoint = [ "${dumb-init}/bin/dumb-init" ];
  cmd = [ "${app}/bin/skaia-cni" ];
  env.CNI_PLUGINS_SRC = cniPlugins;
  env.PATH = lib.makeBinPath [ iproute2 nftables tailscale ];
  passthru = { inherit cargoNix app; };
}
