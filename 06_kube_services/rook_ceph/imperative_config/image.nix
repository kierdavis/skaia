{ callPackage, ceph-client, generatedCargoNix, lib, stamp }:

let
  cargoNix = generatedCargoNix {
    name = "rook-ceph-imperative-config";
    src = builtins.filterSource (path: type: baseNameOf path != "target") ./crate;
  };
  app = (callPackage cargoNix {}).rootCrate.build;
in stamp.fromNix {
  name = "stamp-img-skaia-rook-ceph-imperative-config";
  entrypoint = [ "${app}/bin/rook-ceph-imperative-config" ];
  env.PATH = lib.makeBinPath [ ceph-client ];
  passthru = { inherit cargoNix app; };
}
