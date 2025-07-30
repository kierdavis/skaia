{ appliedCargoNix, ceph-client, lib, stamp }:

let
  crate = (appliedCargoNix {
    name = "rook-ceph-imperative-config";
    src = builtins.filterSource (path: type: baseNameOf path != "target") ./crate;
  }).rootCrate.build;
in stamp.fromNix {
  name = "stamp-img-skaia-rook-ceph-imperative-config";
  entrypoint = [ "${crate}/bin/rook-ceph-imperative-config" ];
  env.PATH = lib.makeBinPath [ ceph-client ];
}
