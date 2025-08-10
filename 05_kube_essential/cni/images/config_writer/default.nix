{ callPackage, dumb-init, generatedCargoNix, stamp }:

let
  cargoNix = generatedCargoNix {
    name = "config-writer";
    src = builtins.filterSource (path: type: baseNameOf path != "target") ./crate;
  };
  app = (callPackage cargoNix {}).rootCrate.build;
in stamp.fromNix {
  name = "stamp-img-skaia-config-writer";
  entrypoint = [ "${dumb-init}/bin/dumb-init" ];
  cmd = [ "${app}/bin/config-writer" ];
  passthru = { inherit cargoNix app; };
}
