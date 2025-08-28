{ buildGoModule, dumb-init, stamp }:

let
  app = buildGoModule (_: rec {
    name = "ensouled-skin";
    src = ./src;
    vendorHash = "sha256-1TyFfRL6HTOa+M4CEcHeiReRcPlPNKMneq2AVXS0kX0=";
  });
in stamp.fromNix {
  name = "stamp-img-ensouled-skin";
  entrypoint = [ "${dumb-init}/bin/dumb-init" "${app}/bin/ensouled.skin" ];
  passthru = { inherit app; };
}
