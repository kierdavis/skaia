{
  inputs = {
    crate2nix = {
      type = "github";
      owner = "nix-community";
      repo = "crate2nix";
      rev = "be31feae9a82c225c0fd1bdf978565dc452a483a";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "f81bb6b77e190eb6f93053fb3e917501dbaf6291";
    };
    stamp = {
      type = "github";
      owner = "kierdavis";
      repo = "stamp";
      ref = "main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, crate2nix, nixpkgs, stamp, ... }: {
    packages."x86_64-linux" =
      with import nixpkgs {
        system = "x86_64-linux";
        overlays = [ stamp.overlays.default ];
      };
      rec {
        crate = (crate2nix.tools."x86_64-linux".appliedCargoNix {
          name = "route-advertiser";
          src = ./crate;
        }).rootCrate.build;
        default = callPackage ./image.nix { inherit crate; };
      };
  };
}
