self: super: with self; {
  imageTools = {
    fetch =
      { imageName
      , imageDigest
      , hash
      , name ? lib.strings.sanitizeDerivationName imageName
      }:
      stdenv.mkDerivation {
        inherit name imageName imageDigest;
        nativeBuildInputs = [ crane imageTools.imgtool ];
        phases = [ "fetchPhase" "buildPhase" ];
        fetchPhase = ''
          runHook preFetch
          mkdir -p "$out"
          crane pull --format=oci "$imageName@$imageDigest" "$out/oci"
          runHook postFetch
        '';
        buildPhase = ''
          runHook preBuild
          imgtool post-fetch $out
          runHook postBuild
        '';
        outputHash = hash;
        outputHashMode = "recursive";
      };

    customise =
      { base
      , add ? []
      , run ? null
      , env ? {}
      , entrypoint ? null
      , cmd ? null
      , name ? "${base.name}+custom"
      , vmDiskSize ? 2048
      , vmMemSize ? 512
      }:
      let
        common = stdenv.mkDerivation {
          inherit name base;
          customisationsFile = writeText "customisations.json" (builtins.toJSON {
            inherit add run env entrypoint cmd;
          });
          nativeBuildInputs = [ imageTools.imgtool ];
          phases = [ "buildPhase" ];
          buildPhase = ''
            runHook preBuild
            imgtool customise "$customisationsFile" "$base" "$out"
            runHook postBuild
          '';
        };
      in
        if run != null
        then vmTools.runInLinuxVM (common.overrideAttrs (oldAttrs: {
          preVM = vmTools.createEmptyImage {
            size = vmDiskSize;
            fullName = "disk";
            destination = "disk";
          };
          memSize = vmMemSize;
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ e2fsprogs util-linux ];
          preBuild = ''
            mkdir disk
            mkfs /dev/${vmTools.hd}
            mount /dev/${vmTools.hd} disk
            cd disk
          '';
        }))
        else common;

    fetchPkgs =
      { urls, hash }:
      stdenv.mkDerivation {
        name = "pkgs";
        nativeBuildInputs = [ curl ];
        phases = [ "fetchPhase" ];
        fetchPhase = ''
          mkdir -p $out/imgbuild/pkgs
          cd $out/imgbuild/pkgs
          for url in ${lib.strings.concatMapStringsSep " " lib.escapeShellArg urls}; do
            curl --silent --show-error --fail --location --remote-name "$url"
          done
        '';
        SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
        outputHash = hash;
        outputHashMode = "recursive";
      };

    fetchAPKs = imageTools.fetchPkgs;
    installAPKs = ''apk add --no-cache --no-network --repositories-file=/dev/null /imgbuild/pkgs/*.apk'';

    fetchDEBs = imageTools.fetchPkgs;
    installDEBs = ''apt install -y /imgbuild/pkgs/*.deb && rm -f /var/cache/ldconfig/aux-cache /var/log/apt/history.log /var/log/apt/term.log /var/log/dpkg.log'';

    imgtool = let
      extraPath = lib.makeBinPath [
        coreutils
        gnutar
        pigz
        python3
        rsync
        util-linux
      ];
    in writeShellScriptBin "imgtool" ''
      export PATH="${extraPath}:$PATH"
      exec python3 ${./imgtool.py} "$@"
    '';

    bases = {
      alpine = imageTools.fetch {
        imageName = "docker.io/alpine";
        imageDigest = "sha256:6457d53fb065d6f250e1504b9bc42d5b6c65941d57532c072d929dd0628977d0";
        hash = "sha256-siBcE0RJczoz5hYPz/b8Xz3Qg2sOol85ZlXB/Dz5bzQ=";
      };
    };
  };
}
