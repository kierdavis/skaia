{
  inputs = {
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

  outputs = { self, nixpkgs, stamp, ... }: {
    packages."x86_64-linux" =
      with import nixpkgs {
        system = "x86_64-linux";
        overlays = [ stamp.overlays.default ];
        config.allowUnfree = true; # for Terraform
      };
      {
        default = callPackage ./image.nix {};
      };
  };
}
