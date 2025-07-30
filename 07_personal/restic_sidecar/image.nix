{ dumb-init, lib, restic, stamp }:

stamp.fromNix {
  name = "stamp-img-skaia-restic-sidecar";
  runOnHost = ''
    mkdir -p bin var/spool/cron/crontabs
    ln -sfT ${./main.sh} bin/main.sh
    ln -sfT ${./backup.sh} bin/backup.sh
  '';
  entrypoint = [ "${dumb-init}/bin/dumb-init" "/bin/main.sh" ];
  env.PATH = lib.makeBinPath [ restic ];
}
