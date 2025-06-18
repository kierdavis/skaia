{ imageTools }:

imageTools.customise {
  base = imageTools.customise {
    base = imageTools.bases.alpine;
    # top-level: dumb-init, restic
    add = [(imageTools.fetchAPKs (pkgs: with pkgs; [
      dumb-init
      restic
    ]))];
    run = imageTools.installAPKs;
    newLayerHash = "sha256-IFlso/kxq+8czRyiC1u/HIG1rz9XPmH/snKb9CRSmco=";
  };
  add = [
    { src = ./main.sh; dest = "/bin/main.sh"; }
    { src = ./backup.sh; dest = "/bin/backup.sh"; }
  ];
  entrypoint = [ "/usr/bin/dumb-init" "/bin/main.sh" ];
}
