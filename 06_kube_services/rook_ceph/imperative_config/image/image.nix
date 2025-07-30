{ ceph, crate, lib, stamp }:

let
  # XXX: libs3 fails to build and I cba to understand why.
  ceph' = ceph.override { libs3 = null; };
in stamp.fromNix {
  name = "stamp-img-skaia-rook-ceph-imperative-config";
  entrypoint = [ "${crate}/bin/rook-ceph-imperative-config" ];
  env.PATH = lib.makeBinPath [ ceph' ];
}
