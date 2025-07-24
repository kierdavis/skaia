{ dumb-init
, lib
, stamp

, coreutils-full
, curl
, file
, findutils
, fping
, git
, gnugrep
, gnutar
, gzip
, htop
, iana-etc
, iftop
, iproute2
, iptables-legacy
, iputils
, jnettop
, jq
, kmod
, less
, lsof
, man
, ncdu
, nettools
, nftables
, nmap
, openssh
, pciutils
, procps
, psmisc
, strace
, sysstat
, tailscale
, tcpdump
, usbutils
, util-linux
, wget
, which
}:

let
  pkgs = [
    coreutils-full
    curl
    file
    findutils
    fping
    git
    gnugrep
    gnutar
    gzip
    htop
    iana-etc
    iftop
    iproute2
    iptables-legacy
    iputils
    jnettop
    jq
    kmod
    less
    lsof
    man
    ncdu
    nettools
    nftables
    nmap
    openssh
    pciutils
    procps
    psmisc
    strace
    sysstat
    tailscale
    tcpdump
    usbutils
    util-linux
    wget
    which
  ];
in stamp.fromNix {
  name = "stamp-img-skaia-debug";
  entrypoint = [ "${dumb-init}/bin/dumb-init" ];
  cmd = [ "${coreutils-full}/bin/sleep" "infinity" ];
  workingDir = "/root";
  env.USER = "root";
  env.PATH = lib.makeBinPath pkgs;
  env.MANPATH = lib.makeSearchPathOutput "man" "share/man" pkgs;
}
