{ appliedCargoNix, dumb-init, stamp }:

let
  crate = (appliedCargoNix {
    name = "config-writer";
    src = builtins.filterSource (path: type: baseNameOf path != "target") ./crate;
  }).rootCrate.build;
in stamp.fromNix {
  name = "stamp-img-skaia-config-writer";
  entrypoint = [ "${dumb-init}/bin/dumb-init" ];
  cmd = [ "${crate}/bin/config-writer" ];
}
