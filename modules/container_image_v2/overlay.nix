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

    append =
      { from
      , content ? null
      , script ? null
      , env ? {}
      , name ? "${from.name}+append"
      , vmDiskSize ? 2048
      , vmMemSize ? 512
      }:
      let
        common = stdenv.mkDerivation {
          inherit name from;
          nativeBuildInputs = [ imageTools.imgtool ];
          phases = [ "buildPhase" ];
          buildPhase = ''
            runHook preBuild
            imgtool append \
              ${if content != null then lib.escapeShellArg "--content=${content}" else ""} \
              ${if script != null then lib.escapeShellArg "--script=${script}" else ""} \
              ${lib.strings.concatStringsSep " " (lib.attrsets.mapAttrsToList (n: v: lib.escapeShellArg "--env=${n}=${v}") env)} \
              "$from" "$out"
            runHook postBuild
          '';
        };
      in
        if script != null
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

    #seq = steps: lib.foldl (img: transformer: transformer img) (builtins.head steps) (builtins.tail steps);

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
  };
}
