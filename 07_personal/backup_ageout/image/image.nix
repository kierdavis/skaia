{ lib, python3, restic, stamp }:

stamp.fromNix {
  name = "stamp-img-skaia-backup-ageout";
  entrypoint = [ "${python3}/bin/python3" "${./main.py}" ];
  env.PATH = lib.makeBinPath [ restic ];
}
