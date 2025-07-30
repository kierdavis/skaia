{ fetchzip, stamp }:

let
  # Can't use cni-plugins from nixpkgs because its binaries contain references to other store paths.
  # We need 100% statically-linked binaries here.
  plugins = fetchzip {
    name = "plugins";
    url = "https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz";
    hash = "sha256-mNrk25QefK73rAWI2i/9EQpksWdxYVcUK4z9Rru3G8M=";
    stripRoot = false;
    postFetch = ''
      mkdir $out/.keep
      mv $out/{bridge,host-local,loopback} $out/.keep
      rm $out/*
      mv $out/.keep/* $out
      rmdir $out/.keep
    '';
  };
in stamp.fromNix {
  name = "stamp-img-skaia-plugin-installer";
  entrypoint = [ "sh" "-c" "cp -v ${plugins}/* /dest/" ];
  passthru = { inherit plugins; };
}
