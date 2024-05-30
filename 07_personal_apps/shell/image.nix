with import <nixpkgs> {};

dockerTools.streamNixShellImage {
  drv = mkShell {
    buildInputs = [
      backblaze-b2
      bashInteractive
      bc
      coreutils
      curl
      file
      fping
      fzf
      gnupg
      htop
      iftop
      iproute
      iputils
      jnettop
      jq
      kakoune
      kubectl
      kubernetes-helm
      lsof
      man-pages
      ncdu
      nettools
      nix
      nmap
      pass
      pbzip2
      pigz
      procps
      psmisc
      pv
      rclone
      restic
      ripgrep
      rsync
      sysstat
      talosctl
      tcpdump
      terraform
      tmux
      tree
      unzip
      util-linux
      wget
      zip
    ];
  };
  homeDirectory = "/home";
}
