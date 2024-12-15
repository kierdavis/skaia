{ curl, imageTools, lib, stdenv }:

imageTools.append {
  from = imageTools.fetch {
    imageName = "docker.io/linuxserver/jellyfin";
    imageDigest = "sha256:a893c3ca1c0ff89f13a0877c6e8caf285a482aa188c6ee20e1cfdfdb6d52e906";
    hash = "sha256-NtcW3RRTLV4n7NvNuLJ0epOaHsm2TQKFlu2N0RP9nWc=";
  };
  content = stdenv.mkDerivation {
    name = "jellyfin-debs";
    nativeBuildInputs = [ curl ];
    phases = [ "fetchPhase" ];
    fetchPhase = ''
      mkdir -p $out/debs
      cd $out/debs
      curl --silent --show-error --fail --remote-name \
        http://archive.ubuntu.com/ubuntu/pool/universe/i/intel-compute-runtime/intel-opencl-icd_23.43.27642.40-1ubuntu3_amd64.deb
      curl --silent --show-error --fail --remote-name \
        http://archive.ubuntu.com/ubuntu/pool/universe/l/llvm-toolchain-14/libclang-cpp14t64_14.0.6-19build4_amd64.deb
      curl --silent --show-error --fail --remote-name \
        http://archive.ubuntu.com/ubuntu/pool/universe/i/intel-graphics-compiler/libigc1_1.0.15468.25-2build1_amd64.deb
      curl --silent --show-error --fail --remote-name \
        http://archive.ubuntu.com/ubuntu/pool/universe/i/intel-graphics-compiler/libigdfcl1_1.0.15468.25-2build1_amd64.deb
      curl --silent --show-error --fail --remote-name \
        http://archive.ubuntu.com/ubuntu/pool/universe/i/intel-gmmlib/libigdgmm12_22.3.17%2bds1-1_amd64.deb
      curl --silent --show-error --fail --remote-name \
        http://archive.ubuntu.com/ubuntu/pool/universe/l/llvm-toolchain-14/libllvm14t64_14.0.6-19build4_amd64.deb
      curl --silent --show-error --fail --remote-name \
        http://archive.ubuntu.com/ubuntu/pool/universe/s/spirv-llvm-translator-14/libllvmspirvlib14_14.0.0-12build1_amd64.deb
      curl --silent --show-error --fail --remote-name \
        http://archive.ubuntu.com/ubuntu/pool/universe/o/opencl-clang-14/libopencl-clang14_14.0.0-4build2_amd64.deb
    '';
    outputHash = "sha256-oA+BCexa+lpTLgiqDseagUJNme5+EHp5bgBGBE/bOsk=";
    outputHashMode = "recursive";
  };
  script = ''
    #!/bin/sh
    set -o errexit -o nounset
    apt install -y /debs/*
    rm -rf \
      /debs \
      /var/cache/ldconfig/aux-cache \
      /var/log/apt/history.log \
      /var/log/apt/term.log \
      /var/log/dpkg.log
  '';
  #hash = lib.fakeHash;
}
