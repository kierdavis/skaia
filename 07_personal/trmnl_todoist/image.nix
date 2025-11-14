{ lib, python3, stamp }:

let
  python3' = python3.withPackages (py: with py; [ requests ]);
in stamp.fromNix {
  name = "stamp-img-skaia-trmnl-todoist";
  entrypoint = [ "${python3'}/bin/python3" "${./main.py}" ];
}
