{ callPackage, dumb-init, generatedCargoNix, iproute2, lib, nftables, stamp, tailscale }:

let
  cargoNix = generatedCargoNix {
    name = "skaia-cni";
    src = builtins.filterSource (path: type: baseNameOf path != "target") ./crate;
  };
  app = (callPackage cargoNix {}).rootCrate.build;
in stamp.fromNix {
  name = "stamp-img-skaia-cni";
  entrypoint = [ "${dumb-init}/bin/dumb-init" ];
  cmd = [ "${app}/bin/skaia-cni" ];
  env.PATH = lib.makeBinPath [ iproute2 nftables tailscale ];
  passthru = { inherit cargoNix app; };
}
