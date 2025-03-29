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

    fetchPkgs =
      { urls, hash }:
      {
        src = stdenv.mkDerivation {
          name = "pkgs";
          nativeBuildInputs = [ curl ];
          phases = [ "fetchPhase" ];
          fetchPhase = ''
            mkdir -p $out
            cd $out
            for url in ${lib.strings.concatMapStringsSep " " lib.escapeShellArg urls}; do
              curl --silent --show-error --fail --location --remote-name "$url"
            done
          '';
          SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
          outputHash = hash;
          outputHashMode = "recursive";
          enableParallelBuilding = true;
        };
        dest = "/imgbuild/pkgs";
      };

    fetchAPKs = imageTools.fetchPkgs;
    installAPKs = ''apk add --no-cache --no-network --repositories-file=/dev/null /imgbuild/pkgs/*.apk'';

    fetchDEBs = imageTools.fetchPkgs;
    installDEBs = ''apt install -y /imgbuild/pkgs/*.deb && rm -f /var/cache/ldconfig/aux-cache /var/log/apt/history.log /var/log/apt/term.log /var/log/dpkg.log'';

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
        name = "alpine-cargo-image";
        base = imageTools.bases.alpine;
        add = [(imageTools.fetchAPKs {
          urls = [
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/binutils-2.41-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/brotli-libs-1.1.0-r1.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/c-ares-1.27.0-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/ca-certificates-20240226-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/cargo-1.76.0-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/gcc-13.2.1_git20231014-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/gmp-6.3.0-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/isl26-0.26-r1.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/jansson-2.14-r4.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libatomic-13.2.1_git20231014-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libcurl-8.9.1-r1.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libffi-3.4.4-r3.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libgcc-13.2.1_git20231014-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libgomp-13.2.1_git20231014-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libidn2-2.3.4-r4.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libstdc++-13.2.1_git20231014-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libunistring-1.1-r2.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libxml2-2.11.8-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/llvm17-libs-17.0.5-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/mpc1-1.3.1-r1.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/mpfr4-4.2.1-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/musl-dev-1.2.4_git20230717-r4.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/nghttp2-libs-1.58.0-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/rust-1.76.0-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/scudo-malloc-17.0.5-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/xz-libs-5.4.5-r0.apk"
            "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/zstd-libs-1.5.5-r8.apk"
          ];
          hash = "sha256-e4/ATyyrRYDWBkmMEjVG2fdlcGRbKaWf0qeKN6GukS4=";
        })];
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
