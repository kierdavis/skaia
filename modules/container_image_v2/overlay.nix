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
        enableParallelBuilding = true;
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
      , newLayerHash ? null
      }:
      let
        newLayer = stdenv.mkDerivation ({
          inherit base;
          name = "${name}-newlayer";
          nativeBuildInputs = [ imageTools.imgtool ];
          phases = [ "buildPhase" ];
          buildPhase = ''
            runHook preBuild
            imgtool create-layer "$customisations" "$base" "$out"
            runHook postBuild
          '';
          customisations = writeText "customisations.json" (builtins.toJSON {
            inherit add run;
          });
          enableParallelBuilding = true;
        } // (if newLayerHash != null then {
          outputHash = newLayerHash;
          outputHashMode = "recursive";
        } else {}));

        newLayer' = if run != null
          then vmTools.runInLinuxVM (newLayer.overrideAttrs (oldAttrs: {
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
          else newLayer;
      in
        stdenv.mkDerivation {
          inherit name base;
          nativeBuildInputs = [ imageTools.imgtool ];
          phases = [ "buildPhase" ];
          buildPhase = ''
            runHook preBuild
            imgtool customise "$customisations" "$base" "$out"
            runHook postBuild
          '';
          customisations = writeText "customisations.json" (builtins.toJSON {
            newLayer = if add != [] || run != null then newLayer' else null;
            inherit env entrypoint cmd;
          });
          enableParallelBuilding = true;
        };

    apkInventory = import ./apk-inventory.nix {
      inherit (self) fetchurl;
      inherit (self.lib) fakeHash;
    };

    fetchAPKs = callback: {
      src = stdenv.mkDerivation {
        name = "apks";
        phases = [ "buildPhase" ];
        srcs = callback self.imageTools.apkInventory;
        buildPhase = ''
          runHook preBuild
          mkdir -p "$out"
          cd "$out"
          for src in $srcs; do
            dest="''${src##*/}"
            dest="''${dest#*-}"
            ln -sfT "$src" "$dest"
          done
          runHook postBuild
        '';
        enableParallelBuilding = true;
      };
      dest = "/imgbuild/pkgs";
    };

    installAPKs = ''apk add --no-cache --no-network --repositories-file=/dev/null /imgbuild/pkgs/*.apk'';

    compileRustExecutable =
      { name
      , src
      , cargoToml
      , cargoLock
      , dest ? "/bin/${name}"
      , compiledDepsLayerHash ? null
      , compiledAppLayerHash ? null
      }:
      let
        vendoredDeps = rustPlatform.importCargoLock { lockFile = cargoLock; };
        compiledDeps = imageTools.customise {
          name = "${name}-compiled-deps";
          base = imageTools.bases.cargo;
          add = [
            { src = cargoToml; dest = "/crate/Cargo.toml"; }
            { src = cargoLock; dest = "/crate/Cargo.lock"; }
            {
              src = writeText "main.rs" "fn main() { unreachable!() }";
              dest = "/crate/src/main.rs";
            }
            {
              src = vendoredDeps;
              # An idiosyncracy of importCargoLock is that the vendor directory must be located
              # at a path with the same name as the importCargoLock derivation, relative to the
              # directory in which 'cargo build' will be run.
              dest = "/crate/${vendoredDeps.name}";
            }
          ];
          run = ''
            cd /crate
            ln -sfT ${vendoredDeps.name}/.cargo .cargo
            cargo build --locked --offline --release
            rm -rf src target/.rustc_info.json
          '';
          vmMemSize = 2048;
          newLayerHash = compiledDepsLayerHash;
        };
        compiledApp = imageTools.customise {
          name = "${name}-compiled";
          base = compiledDeps;
          add = [{ inherit src; dest = "/crate/src"; }];
          run = ''
            cd /crate
            touch src/main.rs  # so cargo knows a rebuild is necessary
            cargo build --locked --offline --release
            rm -rf src target/.rustc_info.json
          '';
          newLayerHash = compiledAppLayerHash;
        };
      in
        {
          from = compiledApp;
          src = "/crate/target/release/${name}";
          inherit dest;
        };

    bases = {
      alpine = imageTools.fetch {
        imageName = "docker.io/alpine";
        imageDigest = "sha256:6457d53fb065d6f250e1504b9bc42d5b6c65941d57532c072d929dd0628977d0";
        hash = "sha256-siBcE0RJczoz5hYPz/b8Xz3Qg2sOol85ZlXB/Dz5bzQ=";
      };
      cargo = imageTools.customise {
        name = "alpine-cargo";
        base = imageTools.bases.alpine;
        add = [(imageTools.fetchAPKs (pkgs: with pkgs; [
          binutils
          brotli-libs
          c-ares
          ca-certificates
          cargo
          gcc
          gmp
          isl26
          jansson
          libatomic
          libcurl
          libffi
          libgcc
          libgomp
          libidn2
          libstdcxx
          libunistring
          libxml2
          llvm17-libs
          mpc1
          mpfr4
          musl-dev
          nghttp2-libs
          rust
          scudo-malloc
          xz-libs
          zstd-libs
        ]))];
        run = imageTools.installAPKs;
        newLayerHash = "sha256-IlmaoNnPfotpJWYZpMV7Q4dJlHXHb7kPWiXp9DXZfBs=";
      };
    };

    imgtool = let
      extraPath = lib.makeBinPath [
        coreutils
        crane
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
