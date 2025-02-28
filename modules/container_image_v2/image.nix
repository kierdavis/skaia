let
  bootstrapPkgs = import <nixpkgs> {};

  pkgs = import (bootstrapPkgs.fetchzip {
    url = "https://github.com/NixOS/nixpkgs/archive/9ecb50d2fae8680be74c08bb0a995c5383747f89.tar.gz";
    hash = "sha256-b4JrUmqT0vFNx42aEN9LTWOHomkTKL/ayLopflVf81U=";
  }) {
    overlays = [ (import ./overlay.nix) ];
  };

in pkgs.callPackage <src> {}
