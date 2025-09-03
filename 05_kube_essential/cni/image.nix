{ callPackage, dumb-init, generatedCargoNix, lib, stamp, tailscale }:

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
  env.PATH = lib.makeBinPath [ tailscale ];
  passthru = { inherit cargoNix app; };
}
