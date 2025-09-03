{ buildGoModule, dumb-init, stamp }:

let
  app = buildGoModule (_: rec {
    name = "ensouled-skin";
    src = ./src;
    vendorHash = "sha256-6sQpGnCPs4otcgXwGIdGEbCXwdK2y5mgniGmjYMV2lM=";
  });
in stamp.fromNix {
  name = "stamp-img-ensouled-skin";
  entrypoint = [ "${dumb-init}/bin/dumb-init" "${app}/bin/ensouled.skin" ];
  passthru = { inherit app; };
}
