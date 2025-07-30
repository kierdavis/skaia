{ curl, lib, python3, restic, stamp, unzip }:

let
  python3' = python3.withPackages (py: with py; [ requests ]);
in stamp.fromNix {
  name = "stamp-img-skaia-refern-backup";
  entrypoint = [ "${python3'}/bin/python3" "${./main.py}" ];
  env.PATH = lib.makeBinPath [ curl restic unzip ];
}
