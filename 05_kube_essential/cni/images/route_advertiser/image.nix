{ crate, dumb-init, lib, stamp, tailscale }:

stamp.fromNix {
  name = "stamp-img-skaia-route-advertiser";
  entrypoint = [ "${dumb-init}/bin/dumb-init" ];
  cmd = [ "${crate}/bin/route-advertiser" ];
  env.PATH = lib.makeBinPath [ tailscale ];
}
