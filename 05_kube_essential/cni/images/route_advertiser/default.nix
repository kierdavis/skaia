{ callPackage, dumb-init, generatedCargoNix, lib, stamp, tailscale }:

let
  cargoNix = generatedCargoNix {
    name = "route-advertiser";
    src = builtins.filterSource (path: type: baseNameOf path != "target") ./crate;
  };
  app = (callPackage cargoNix {}).rootCrate.build;
in stamp.fromNix {
  name = "stamp-img-skaia-route-advertiser";
  entrypoint = [ "${dumb-init}/bin/dumb-init" ];
  cmd = [ "${app}/bin/route-advertiser" ];
  env.PATH = lib.makeBinPath [ tailscale ];
  passthru = { inherit cargoNix app; };
}
