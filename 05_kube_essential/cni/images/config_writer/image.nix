{ crate, dumb-init, stamp }:

stamp.fromNix {
  name = "stamp-img-skaia-config-writer";
  entrypoint = [ "${dumb-init}/bin/dumb-init" ];
  cmd = [ "${crate}/bin/config-writer" ];
}
