{ dumb-init, redstore, stamp }:

stamp.fromNix {
  name = "stamp-img-skaia-redstore";
  entrypoint = [ "${dumb-init}/bin/dumb-init" "${redstore}/bin/redstore" ];
}
