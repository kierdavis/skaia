{ bash
, coreutils
, dumb-init
, gnused
, hydra
, lib
, openssh
, nix
, python3Packages # { supervisor }
, shadow
, stamp
, util-linux
, writeShellScript
, writeText
}:

let
  maxJobs = 1;
  cores = 2;

  nixbldUIDs = builtins.map builtins.toString (lib.lists.range 1 maxJobs);
  passwd = let
    rootEntry = "root:x:0:0:System administrator:/root:${bash}/bin/bash\n";
    nixbldEntry = uid: "nixbld${uid}:x:${uid}:1:Nix build user ${uid}:/var/empty:${shadow}/bin/nologin\n";
    entries = [ rootEntry ] ++ builtins.map nixbldEntry nixbldUIDs;
  in writeText "passwd" (lib.strings.concatStrings entries);
  shadow = let
    rootEntry = "root:!:1::::::\n";
    nixbldEntry = uid: "nixbld${uid}:!:1::::::\n";
    entries = [ rootEntry ] ++ builtins.map nixbldEntry nixbldUIDs;
  in writeText "shadow" (lib.strings.concatStrings entries);
  group = writeText "group" ''
    root:x:0:
    nixbld:x:1:${lib.strings.concatMapStringsSep "," (uid: "nixbld${uid}") nixbldUIDs}
  '';

  sshConf = writeText "ssh_config" ''
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
  '';

  nixMachinesEntry = m: (lib.concatStringsSep " " [
    m.url
    m.system
    (m.sshIdentity or "-")
    (builtins.toString (m.maxJobs or 1))
    (builtins.toString (m.speedFactor or "-"))
    (lib.concatStringsSep "," (m.supportedFeatures or ["-"]))
    (lib.concatStringsSep "," (m.requiredFeatures or ["-"]))
    (m.sshHostKeyBase64 or "-")
  ]) + "\n";
  nixMachines = writeText "machines" (lib.strings.concatMapStrings nixMachinesEntry [
    { url = "ssh://localhost"; system = "x86_64-linux"; speedFactor = cores; }
    { url = "ssh://nixremotebuild@coloris.tail.skaia.cloud"; system = "x86_64-linux"; speedFactor = 4; supportedFeatures = ["kvm"]; }
  ]);
  baseNixConf = writeText "nix.conf" ''
    builders = @${nixMachines}
    builders-use-substitutes = true
    cores = ${builtins.toString cores}
    extra-experimental-features = flakes nix-command
    max-jobs = ${builtins.toString maxJobs}
    require-sigs = true
    sandbox = false
    substituters = https://cache.nixos.org/
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= hydra.personal.svc.kube.skaia.cloud-1:SFVF30Hf3FSqd3VX8nHhymQN9HkFL1PdLHQLmdMbDwE=
  '';
  finalNixConf = "/etc/nix/nix.conf";

  baseHydraConf = writeText "hydra.conf" ''
    use-substitutes = 1
  '';
  finalHydraConf = "/etc/hydra.conf";

  supervisorConf = writeText "supervisord.conf" ''
    [supervisord]
    logfile=/dev/null
    logfile_maxbytes=0
    logfile_backups=0
    nodaemon=true

    [program:server]
    command=${hydra}/bin/hydra-server --port=80
    autorestart=true
    stdout_logfile=/dev/stderr
    stdout_logfile_maxbytes=0
    stdout_logfile_backups=0
    stderr_logfile=/dev/stderr
    stderr_logfile_maxbytes=0
    stderr_logfile_backups=0

    [program:evaluator]
    command=${coreutils}/bin/nice ${util-linux}/bin/ionice --class idle ${hydra}/bin/hydra-evaluator
    autorestart=true
    stdout_logfile=/dev/stderr
    stdout_logfile_maxbytes=0
    stdout_logfile_backups=0
    stderr_logfile=/dev/stderr
    stderr_logfile_maxbytes=0
    stderr_logfile_backups=0

    [program:queue-runner]
    command=${coreutils}/bin/nice ${util-linux}/bin/ionice --class idle ${hydra}/bin/hydra-queue-runner
    autorestart=true
    stdout_logfile=/dev/stderr
    stdout_logfile_maxbytes=0
    stdout_logfile_backups=0
    stderr_logfile=/dev/stderr
    stderr_logfile_maxbytes=0
    stderr_logfile_backups=0
  '';

  main = writeShellScript "main" ''
    cat ${baseNixConf} > ${finalNixConf}
    echo "extra-substituters = s3://$BUCKET_NAME?endpoint=http://$BUCKET_HOST&region=$BUCKET_REGION" >> ${finalNixConf}

    cat ${baseHydraConf} > ${finalHydraConf}
    echo "store_uri = s3://$BUCKET_NAME?compression=zstd&endpoint=http://$BUCKET_HOST&log-compression=br&ls-compression=br&parallel-compression=true&region=$BUCKET_REGION&secret-key=/nix-signing-secret-key&write-nar-listing=1" >> ${finalHydraConf}

    ${nix}/bin/nix-store --load-db < /nix-path-registration
    ls /nix/store | ${gnused}/bin/sed s,^,/nix/store/, | ${nix}/bin/nix store sign --key-file /nix-signing-secret-key --stdin

    exec ${python3Packages.supervisor}/bin/supervisord --configuration=${supervisorConf}
  '';

in stamp.fromNix {
  name = "stamp-img-skaia-hydra";
  runOnHost = ''
    mkdir -p etc/{nix,ssh} var/empty
    ln -sfT ${passwd} etc/passwd
    ln -sfT ${shadow} etc/shadow
    ln -sfT ${group} etc/group
    ln -sfT ${sshConf} etc/ssh/ssh_config
  '';
  entrypoint = [ "${dumb-init}/bin/dumb-init" ];
  cmd = [ "${main}" ];
  env = {
    LOGNAME = "root";
    HOME = "/root";
    HYDRA_CONFIG = finalHydraConf;
    HYDRA_DATA = "/var/lib/hydra";
    NIX_REMOTE_SYSTEMS = "${nixMachines}";
    PATH = lib.makeBinPath [ hydra openssh nix ];
  };
  withRegistration = true;
}
