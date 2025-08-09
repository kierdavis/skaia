{ appliedCargoNix, dumb-init, lib, stamp, tailscale }:

let
  app = (appliedCargoNix {
    name = "route-advertiser";
    src = builtins.filterSource (path: type: baseNameOf path != "target") ./crate;
  }).rootCrate.build;
in stamp.fromNix {
  name = "stamp-img-skaia-route-advertiser";
  entrypoint = [ "${dumb-init}/bin/dumb-init" ];
  cmd = [ "${app}/bin/route-advertiser" ];
  env.PATH = lib.makeBinPath [ tailscale ];
  passthru = { inherit app; };
}
