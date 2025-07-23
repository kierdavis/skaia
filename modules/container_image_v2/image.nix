let
  bootstrapPkgs = import <nixpkgs> {};

  pkgs = import (bootstrapPkgs.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "f81bb6b77e190eb6f93053fb3e917501dbaf6291";
    hash = "sha256-4UkojxOwl+VdkAbFIUXr7a9r6p0XdLUd8lUJVeUWqTM=";
  }) {
    overlays = [ (import ./overlay.nix) ];
  };

in pkgs.callPackage <src> {}
