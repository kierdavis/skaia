{ imageTools }:

imageTools.customise {
  base = imageTools.customise {
    base = imageTools.bases.alpine;
    # top-level: python3, restic
    add = [(imageTools.fetchAPKs (pkgs: with pkgs; [
      gdbm
      libbz2
      libexpat
      libffi
      libgcc
      libncursesw
      libpanelw
      libstdcxx
      mpdecimal
      ncurses-terminfo-base
      pyc
      python3
      python3-pyc
      python3-pycache-pyc0
      readline
      restic
      sqlite-libs
      xz-libs
    ]))];
    run = imageTools.installAPKs;
    newLayerHash = "sha256-8HZ2GjeN93VyxjSgR21je49j5bZMTcEICtxr2aA15Zs=";
  };
  add = [{
    src = ./main.py;
    dest = "/main.py";
  }];
  entrypoint = [ "/usr/bin/python3" "/main.py" ];
}
