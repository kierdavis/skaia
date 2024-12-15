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
      , content ? ""
      , script ? ""
      , hash ? null
      , name ? "${from.name}+append"
      , vmDiskSize ? 2048
      , vmMemSize ? 512
      }:
      let
        common = stdenv.mkDerivation ({
          inherit name from content script;
          nativeBuildInputs = [ imageTools.imgtool ];
          phases = [ "buildPhase" ];
          buildPhase = ''
            runHook preBuild
            imgtool append ''${content:+--content="$content"} ''${script:+--script="$script"} "$from" "$out"
            runHook postBuild
          '';
        } // (if hash != null then {
          outputHash = hash;
          outputHashMode = "recursive";
        } else {}));
      in
        if script != ""
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
