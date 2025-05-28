{ imageTools }:

imageTools.customise {
  base = imageTools.customise {
    base = imageTools.bases.alpine;
    # top-level: curl, python3, py3-requests, restic, unzip
    add = [(imageTools.fetchAPKs (pkgs: with pkgs; [
      brotli-libs
      ca-certificates
      c-ares
      curl
      gdbm
      libbz2
      libcurl
      libexpat
      libffi
      libgcc
      libidn2
      libncursesw
      libpanelw
      libpsl
      libstdcxx
      libunistring
      mpdecimal
      ncurses-terminfo-base
      nghttp2-libs
      py3-certifi
      py3-certifi-pyc
      py3-charset-normalizer
      py3-charset-normalizer-pyc
      py3-idna
      py3-idna-pyc
      py3-requests
      py3-requests-pyc
      py3-urllib3
      py3-urllib3-pyc
      pyc
      python3
      python3-pyc
      python3-pycache-pyc0
      readline
      restic
      sqlite-libs
      unzip
      xz-libs
    ]))];
    run = imageTools.installAPKs;
    newLayerHash = "sha256-jz4gUQivnnYRsitcwtMhjTINg0gN1o0ys4dE05IU2s0=";
  };
  add = [{
    src = ./main.py;
    dest = "/main.py";
  }];
  cmd = [ "/usr/bin/python3" "/main.py" ];
}
