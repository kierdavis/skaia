{ bashInteractive
, coreutils-full
, dumb-init
, lib
, nix
, nixpkgs
, shadow
, stamp
, util-linux
, writeShellScript
, writeShellScriptBin
, writeText
}:

let
  preinstalledPackageNames = [
    "backblaze-b2"
    "bashInteractive"
    "bc"
    "cargo"
    "coreutils-full"
    "curl"
    "file"
    "findutils"
    "fping"
    "fzf"
    "git"
    "glpk"
    "gnugrep"
    "gnupg"
    "gnused"
    "gnutar"
    "gzip"
    "htop"
    "iana-etc"
    "iftop"
    "iproute2"
    "iputils"
    "jnettop"
    "jq"
    "kakoune"
    "kubectl"
    #"kubernetes-helm"
    "less"
    "lsof"
    "man"
    "man-pages"
    "ncdu"
    "nettools"
    "nix"
    "nmap"
    "openssh"
    "pass"
    "pbzip2"
    "pigz"
    "procps"
    "psmisc"
    "pv"
    "rclone"
    "restic"
    "ripgrep"
    "rsync"
    "strace"
    "sysstat"
    "talosctl"
    "tcpdump"
    #"terraform"
    "tmux"
    "tree"
    "unzip"
    "util-linux"
    "wget"
    "which"
    "zip"
  ];
  kier = {
    uid = "1001";
    gid = "1001";
  };
  nixbld = {
    uids = builtins.map builtins.toString (lib.lists.range 1 1);
    gid = "1";
  };
  etcPasswd = let
    rootEntry = "root:x:0:0:System administrator:/root:${bashInteractive}/bin/bash\n";
    kierEntry = "kier:x:${kier.uid}:${kier.gid}:Kier Davis:/home/kier:${bashInteractive}/bin/bash\n";
    nixbldEntry = uid: "nixbld${uid}:x:${uid}:${nixbld.gid}:Nix build user ${uid}:/var/empty:${shadow}/bin/nologin\n";
    entries = [ rootEntry kierEntry ] ++ builtins.map nixbldEntry nixbld.uids;
  in writeText "passwd" (lib.strings.concatStrings entries);
  etcShadow = let
    rootEntry = "root:!:1::::::\n";
    kierEntry = "kier:!:1::::::\n";
    nixbldEntry = uid: "nixbld${uid}:!:1::::::\n";
    entries = [ rootEntry kierEntry ] ++ builtins.map nixbldEntry nixbld.uids;
  in writeText "shadow" (lib.strings.concatStrings entries);
  etcGroup = writeText "group" ''
    root:x:0:
    kier:x:${kier.gid}:
    nixbld:x:${nixbld.gid}:${lib.strings.concatMapStringsSep "," (uid: "nixbld${uid}") nixbld.uids}
  '';
  etcNixRegistry = writeText "registry.json" (builtins.toJSON {
    version = 2;
    flakes = [{
      exact = true;
      from = { type = "indirect"; id = "nixpkgs"; };
      to = { type = "path"; path = nixpkgs; };
    }];
  });
  baseNixConf = writeText "nix.conf" ''
    cores = 1
    experimental-features = flakes nix-command
    max-jobs = 1
    require-sigs = true
    sandbox = false
    substituters = https://cache.nixos.org/
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= hydra.personal.svc.kube.skaia.cloud-1:SFVF30Hf3FSqd3VX8nHhymQN9HkFL1PdLHQLmdMbDwE=
  '';
  runAsUser = writeShellScript "run-as-user" ''
    export HOME=/home/kier
    export LOGNAME=kier
    export MANPATH=/home/kier/.nix-profile/share/man
    export PATH=/home/kier/.nix-profile/bin
    export USER=kier
    exec ${util-linux}/bin/setpriv --reuid=kier --regid=kier --init-groups --inh-caps=-all "$@"
  '';
  # The main (idle) process of the container.
  main = writeShellScript "main" ''
    (
      cat ${baseNixConf}
      if [[ -n "''${NIX_CACHE_BUCKET_NAME:-}" ]]; then
        echo "extra-substituters = s3://$NIX_CACHE_BUCKET_NAME?endpoint=http://$NIX_CACHE_BUCKET_HOST&region=$NIX_CACHE_BUCKET_REGION"
      fi
    ) > /etc/nix/nix.conf
    ${nix}/bin/nix-store --load-db < /nix-path-registration
    export AWS_ACCESS_KEY_ID="''${NIX_CACHE_AWS_ACCESS_KEY_ID:-}"
    export AWS_SECRET_ACCESS_KEY="''${NIX_CACHE_AWS_SECRET_ACCESS_KEY:-}"
    ${coreutils-full}/bin/chown kier:kier /home/kier /ready
    ${runAsUser} ${preinstall} &
    exec ${nix}/bin/nix-daemon
  '';
  preinstall = writeShellScript "preinstall" ''
    ${coreutils-full}/bin/sleep 1
    while [[ ! -e /nix/var/nix/daemon-socket/socket ]]; do
      echo >&2 "waiting for /nix/var/nix/daemon-socket/socket"
      ${coreutils-full}/bin/sleep 1
    done
    ${nix}/bin/nix profile install ${lib.strings.concatMapStringsSep " " (x: "'nixpkgs#${x}'") preinstalledPackageNames}
    ${coreutils-full}/bin/touch /ready/ready
    echo >&2 "preinstall complete"
  '';
  # Through muscle memory, I create interactive sessions in the container with
  # `kubectl exec -it devenv -- bash`. So let's override `bash` with a script
  # that performs necessary per-session tasks, like switching to the right UID.
  sessionEntrypoint = (writeShellScriptBin "bash" ''
    cd /net/skaia
    exec ${runAsUser} ${bashInteractive}/bin/bash "$@"
  '').overrideAttrs (_: { name = "session-entrypoint"; });

in stamp.fromNix {
  name = "stamp-img-skaia-devenv";
  runOnHost = ''
    mkdir -p etc/nix home/kier net/skaia ready run/current-system tmp var/empty
    ln -sfT ${etcPasswd} etc/passwd
    ln -sfT ${etcShadow} etc/shadow
    ln -sfT ${etcGroup} etc/group
    ln -sfT ${etcNixRegistry} etc/nix/registry.json
    chmod 1777 tmp
  '';
  entrypoint = [ "${dumb-init}/bin/dumb-init" "${main}" ];
  env = {
    NIX_PATH = "nixpkgs=${nixpkgs}";
    NIXPKGS_ALLOW_UNFREE = "1";
    PATH = "${sessionEntrypoint}/bin";
  };
  withRegistration = true;
  passthru = {
    # This derivation is built by Hydra, to ensure everything we want to install at container startup is available in the Nix cache.
    preinstalledPackages = pkgs: pkgs.stdenvNoCC.mkDerivation {
      name = "skaia-devenv-preinstalled-pkgs";
      buildCommand = "mkdir -p $out\ncd $out\n" + lib.strings.concatMapStrings (x: "ln -s ${pkgs.${x}}\n") preinstalledPackageNames;
    };
  };
}
