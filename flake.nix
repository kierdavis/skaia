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
      ref = "release-25.05";
    };
    stamp = {
      type = "github";
      owner = "kierdavis";
      repo = "stamp";
      ref = "main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, crate2nix, stamp, ... }: {
    packages."x86_64-linux" = let
      nixpkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        overlays = [ stamp.overlays.default ];
        config.allowUnfree = true; # for terraform (as used in devenv)
      };
      callPackage = nixpkgs.callPackage;
      appliedCargoNix = crate2nix.tools."x86_64-linux".appliedCargoNix;
    in {
      kubeEssential.cni.images.configWriter = callPackage 05_kube_essential/cni/images/config_writer { inherit appliedCargoNix; };
      kubeEssential.cni.images.pluginInstaller = callPackage 05_kube_essential/cni/images/plugin_installer {};
      kubeEssential.cni.images.routeAdvertiser = callPackage 05_kube_essential/cni/images/route_advertiser { inherit appliedCargoNix; };
      kubeEssential.debug.image = callPackage 05_kube_essential/debug/image.nix {};
      kubeServices.rookCeph.imperativeConfig.image = callPackage 06_kube_services/rook_ceph/imperative_config/image.nix { inherit appliedCargoNix; };
      personal.backup.common.image = callPackage 07_personal/backup/common/image.nix {};
      personal.backupAgeout.image = callPackage 07_personal/backup_ageout/image.nix {};
      personal.devenv.image = callPackage 07_personal/devenv/image.nix {};
      personal.hydra.image = callPackage 07_personal/hydra/image.nix {};
      personal.jellyfin.image = callPackage 07_personal/jellyfin/image.nix {};
      personal.paperless.image = callPackage 07_personal/paperless/image.nix {};
      personal.refernBackup.image = callPackage 07_personal/refern_backup/image.nix {};
      personal.todoistAutomation.image = callPackage 07_personal/todoist_automation/image.nix {};
      personal.transcoding.image = callPackage 07_personal/transcoding/image.nix {};
      personal.valheim.common.image = callPackage 07_personal/valheim/common/image.nix {};
      secret = import secret/packages.nix { inherit nixpkgs; };
    };
    hydraJobs = self.packages."x86_64-linux";
  };
}
