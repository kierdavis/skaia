{
  inputs = {
    self.submodules = true;
    crate2nix = {
      type = "github";
      owner = "nix-community";
      repo = "crate2nix";
      ref = "master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "release-25.11";
    };
    stamp = {
      type = "github";
      owner = "kierdavis";
      repo = "stamp";
      ref = "main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, crate2nix, stamp, ... }: let
    system = "x86_64-linux";
    nixpkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        stamp.overlays.default
        (import 07_personal/redstore/overlay.nix)
      ];
      config.allowUnfree = true; # for terraform (as used in devenv)
    };
    lib = nixpkgs.lib;
    callPackage = nixpkgs.callPackage;
    generatedCargoNix = crate2nix.tools.${system}.generatedCargoNix;
    packages = rec {
      kubeEssential.cni.image = callPackage 05_kube_essential/cni/image.nix { inherit generatedCargoNix; };
      kubeEssential.debug.image = callPackage 05_kube_essential/debug/image.nix {};
      kubeServices.grafanaBackup.image = callPackage 06_kube_services/grafana_backup/image.nix {};
      kubeServices.rookCeph.imperativeConfigImage = callPackage 06_kube_services/rook_ceph/imperative_config_image { inherit generatedCargoNix; };
      personal.backup.common.image = callPackage 07_personal/backup/common/image.nix {};
      personal.devenv.image = callPackage 07_personal/devenv/image.nix { inherit (inputs) nixpkgs; };
      personal.ensouledSkin.image = callPackage 07_personal/ensouled_skin/image.nix {};
      personal.hydra.image = callPackage 07_personal/hydra/image.nix {};
      personal.jellyfin.image = callPackage 07_personal/jellyfin/image.nix {};
      personal.paperless.image = callPackage 07_personal/paperless/image.nix {};
      personal.redstore.image = callPackage 07_personal/redstore/image.nix {};
      personal.todoistAutomation.image = callPackage 07_personal/todoist_automation/image.nix {};
      personal.transcoding.image = callPackage 07_personal/transcoding/image.nix {};
      personal.trmnlTodoist.image = callPackage 07_personal/trmnl_todoist/image.nix {};
      personal.valheim.common.image = callPackage 07_personal/valheim/common/image.nix {};
      secret = import secret/packages.nix { inherit nixpkgs; };
    };
    getDerivAttrRecursive = attr: set: lib.attrsets.filterAttrs
      (_: val: !(val == null || (builtins.isAttrs val && builtins.length (builtins.attrNames val) == 0)))
      (lib.attrsets.mapAttrs
        (_: val: if lib.attrsets.isDerivation val then val.${attr} or null else getDerivAttrRecursive attr val)
        set);
  in {
    packages.${system} = packages;
    hydraJobs = packages // {
      crate2nix = builtins.elemAt (builtins.filter (x: lib.strings.hasPrefix "rust_crate2nix-" x.name) packages.kubeEssential.cni.image.cargoNix.buildInputs) 0;
      cargoNix = getDerivAttrRecursive "cargoNix" packages;
      packingPlan = getDerivAttrRecursive "packingPlan" packages;
      devenvPreinstalledPackages = packages.personal.devenv.image.preinstalledPackages nixpkgs;
    };
  };
}
