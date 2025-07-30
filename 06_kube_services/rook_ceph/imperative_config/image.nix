{ appliedCargoNix, ceph, lib, stamp }:

let
  crate = (appliedCargoNix {
    name = "rook-ceph-imperative-config";
    src = builtins.filterSource (path: type: baseNameOf path != "target") ./crate;
  }).rootCrate.build;
  # XXX: libs3 fails to build and I cba to understand why.
  ceph' = ceph.override { libs3 = null; };
in stamp.fromNix {
  name = "stamp-img-skaia-rook-ceph-imperative-config";
  entrypoint = [ "${crate}/bin/rook-ceph-imperative-config" ];
  env.PATH = lib.makeBinPath [ ceph' ];
}
