{ lib, python3, restic, stamp }:

let
  python3' = python3.withPackages (py: with py; [ requests ]);
in stamp.fromNix {
  name = "stamp-img-skaia-todoist-automation";
  entrypoint = [ "${python3'}/bin/python3" "${./main.py}" ];
  env.PATH = lib.makeBinPath [ restic ];
}
