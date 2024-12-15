let
  pkgs = import (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/9ecb50d2fae8680be74c08bb0a995c5383747f89.tar.gz) {
    overlays = [ (import ./overlay.nix) ];
  };

in pkgs.callPackage <src> {}
