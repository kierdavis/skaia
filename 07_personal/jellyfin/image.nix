{ fetchurl, stamp }:

stamp.installDebianPkgs {
  name = "stamp-img-skaia-jellyfin";
  base = stamp.fetch {
    repository = "docker.io/linuxserver/jellyfin";
    digest = "sha256:a893c3ca1c0ff89f13a0877c6e8caf285a482aa188c6ee20e1cfdfdb6d52e906";
    hash = "sha256-XnSgx18nslDvBcGMQbO+mNwFB1fNGsYv8SayWwXrVnU=";
  };
  pkgs = [
    # Top-level packages to install: intel-opencl-icd
    # Discover dependencies using: apt-get install -y --no-install-recommends intel-opencl-icd
    # Generate URLs and hashes using: apt-get download --print-uris PACKAGE...
    (fetchurl {
      url = "http://archive.ubuntu.com/ubuntu/pool/universe/i/intel-compute-runtime/intel-opencl-icd_23.43.27642.40-1ubuntu3_amd64.deb";
      hash = "sha512:6206d64006feb4f0c8384e3b6f218f0737bc1924d470e97292f71b752947a987f801ca4967dbea4bef46c9ca17cc2e0653f415071315ba1b9e017ef48c580751";
    })
    (fetchurl {
      url = "http://archive.ubuntu.com/ubuntu/pool/universe/l/llvm-toolchain-14/libclang-cpp14t64_14.0.6-19build4_amd64.deb";
      hash = "sha512:0d38246e9559e775d52e8b257ca9afffc023faac5e3e2025804c1a78fe88ff97d29f845071ec3043832af14a7480361de95a5c9bde7608460e15ebb10bf0a638";
    })
    (fetchurl {
      url = "http://archive.ubuntu.com/ubuntu/pool/universe/i/intel-gmmlib/libigdgmm12_22.3.17%2bds1-1_amd64.deb";
      hash = "sha512:e94cd667a9b7b6c9e94490267148f5e9b0559f52d380d9ca4ccc016f220f8516d2daa4bc3450dad5a9c877f263f58e534f61cc6612e0e9b7324f37b210f058ac";
    })
    (fetchurl {
      url = "http://archive.ubuntu.com/ubuntu/pool/universe/l/llvm-toolchain-14/libllvm14t64_14.0.6-19build4_amd64.deb";
      hash = "sha512:362545d9fa2e1ed69bb32832022dabc07378179657c071647976e77f2a59276f7e2e40a60b61ab700229902c7ba769f1769432f80e903f26a58e8c4497958f97";
    })
    (fetchurl {
      url = "http://archive.ubuntu.com/ubuntu/pool/universe/s/spirv-llvm-translator-14/libllvmspirvlib14_14.0.0-12build1_amd64.deb";
      hash = "sha512:e55524539e5c32f0d42ba03234a5d73ebb340097ed68b2721bef3de796080dc155f36ff03d3cd0cdcb038aaded09b48882b3dad9246d2d61fecf89c31a78ed7e";
    })
    (fetchurl {
      url = "http://archive.ubuntu.com/ubuntu/pool/universe/o/opencl-clang-14/libopencl-clang14_14.0.0-4build2_amd64.deb";
      hash = "sha512:e5c4df59d999233172462fe36d235f3b6c35a254289a463c69c21d8741b40c4bc189887cf985fa373674a3f96debe9939d156f0a9f0537519a19eeac4faaa461";
    })
    (fetchurl {
      url = "http://archive.ubuntu.com/ubuntu/pool/universe/i/intel-graphics-compiler/libigc1_1.0.15468.25-2ubuntu0.1_amd64.deb";
      hash = "sha512:46d038f7fd077b4af5913fbc60c8b8f7674a0d7a984f6b340de45076f26ed9a75bd13e5543a7a75b252a6298027b6a448aaa8d857af37368a5ca13cf20a6273c";
    })
    (fetchurl {
      url = "http://archive.ubuntu.com/ubuntu/pool/universe/i/intel-graphics-compiler/libigdfcl1_1.0.15468.25-2ubuntu0.1_amd64.deb";
      hash = "sha512:1b8c2ebdc724e365896a6766504b01b84cb7ac6e5a358cf069411b5cf32735df7c90f3c9f27dd44fb08a23b986bf3a10bd9a6ea60ebfe181642c2ce9006b7173";
    })
  ];
  layerHash = "sha256-XGE+UULEdCjy6ivYUISWLiBrR6fpL1GdF/XRgmGPsQc=";
}
