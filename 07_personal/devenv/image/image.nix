{ dumb-init
, lib
, stamp

, backblaze-b2
, bc
, cargo
, coreutils-full
, curl
, file
, findutils
, fping
, fzf
, git
, glpk
, gnugrep
, gnupg
, gnused
, gnutar
, gzip
, htop
, iana-etc
, iftop
, iproute2
, iputils
, jnettop
, jq
, kakoune
, kubectl
, kubernetes-helm
, less
, lsof
, man
, man-pages
, ncdu
, nettools
, nix
, nmap
, openssh
, pass
, pbzip2
, pigz
, procps
, psmisc
, pv
, rclone
, restic
, ripgrep
, rsync
, strace
, sysstat
, talosctl
, tcpdump
, terraform
, tmux
, tree
, unzip
, util-linux
, wget
, which
, zip
}:

stamp.fromNix {
  name = "stamp-img-skaia-devenv";
  entrypoint = [ "${dumb-init}/bin/dumb-init" ];
  cmd = [ "${coreutils-full}/bin/sleep" "infinity" ];
  workingDir = "/net/skaia";
  #user = "kier:kier";
  #env.USER = "kier";
  env.PATH = lib.makeBinPath [
    backblaze-b2
    bc
    cargo
    coreutils-full
    curl
    file
    findutils
    fping
    fzf
    git
    glpk
    gnugrep
    gnupg
    gnused
    gnutar
    gzip
    htop
    iana-etc
    iftop
    iproute2
    iputils
    jnettop
    jq
    kakoune
    kubectl
    kubernetes-helm
    less
    lsof
    man
    man-pages
    ncdu
    nettools
    nix
    nmap
    openssh
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
    strace
    sysstat
    talosctl
    tcpdump
    terraform
    tmux
    tree
    unzip
    util-linux
    wget
    which
    zip
  ];
}
