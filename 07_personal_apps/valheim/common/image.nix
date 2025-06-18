{ fetchurl, imageTools }:

imageTools.customise {
  base = imageTools.fetch {
    imageName = "docker.io/cm2network/steamcmd";
    imageDigest = "sha256:5c8e64503d264b406e81cdb0d6b2d53757b10fb887fd8b5454d664c503bd34f4"; # 'latest' tag
    hash = "sha256-t7SmcaCiWkEc4/K+rCyZSnYduzD/WPQPxVVicWkAeqE=";
  };
  add = builtins.map (src: { inherit src; dest = "/imgbuild/pkgs/${src.name}"; }) [
    # Top-level packages to install: libatomic1 libpulse-dev procps
    # Discover dependencies using: apt-get install -y --no-install-recommends libatomic1 libpulse-dev procps
    # Generate URLs and hashes using: apt-get download --print-uris PACKAGE...
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/d/dbus/libdbus-1-3_1.14.10-1%7edeb12u1_amd64.deb";
      hash = "sha256:18ee0ce5fab9f7b671e87da1e9fa18660e36e04a3402f24bdb8635e0ba1d35f6";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/e/elfutils/libelf1_0.188-2.1_amd64.deb";
      hash = "sha256:619add379c606b3ac6c1a175853b918e6939598a83d8ebadf3bdfd50d10b3c8c";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/e/expat/libexpat1_2.5.0-1%2bdeb12u1_amd64.deb";
      hash = "sha256:c2bd305125bcece5816b2521f293a99499d674cd2dd744416caa4952158ad99d";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/f/flac/libflac12_1.4.2%2bds-2_amd64.deb";
      hash = "sha256:4d8431c274eef13ec9ee2c0bf988c34b4342367dec053b7f69a432525be5b1fe";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/g/gcc-12/libatomic1_12.2.0-14%2bdeb12u1_amd64.deb";
      hash = "sha256:fbd4e154a6b444229ea002cc209df099209c0adc09102e5fd21239a3d2b55e2d";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/g/glib2.0/libglib2.0-0_2.74.6-2%2bdeb12u6_amd64.deb";
      hash = "sha256:2eda0da6027dd90313949176b662885ee820a725471057bfc6b144a866f66ee5";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/g/glib2.0/libglib2.0-bin_2.74.6-2%2bdeb12u6_amd64.deb";
      hash = "sha256:af1fe1c26eb9ebdc2c77e6c1e8b731079d033e426f60f4c94fe96cc179c0e947";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/g/glib2.0/libglib2.0-data_2.74.6-2%2bdeb12u6_all.deb";
      hash = "sha256:6d841ace500f915932cbe4d5d8a699095e6a8dd9f87535becb46a8f5d8ba86e3";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/g/glib2.0/libglib2.0-dev_2.74.6-2%2bdeb12u6_amd64.deb";
      hash = "sha256:55c0a8c6e7800c8cd92f439cd55fc8636a499495aff11691851033a09a79b700";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/g/glib2.0/libglib2.0-dev-bin_2.74.6-2%2bdeb12u6_amd64.deb";
      hash = "sha256:1995ca9f741dd3a0013f7d277f77f274a5702b30fcfdc559d2f2ff36bff44fdb";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/g/glibc/libc-dev-bin_2.36-9%2bdeb12u10_amd64.deb";
      hash = "sha256:db898f3f85e19d4d54a277a0ab479b57566be5b902e6e8ebe814410aa3149e72";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/g/glibc/libc6-dev_2.36-9%2bdeb12u10_amd64.deb";
      hash = "sha256:5597f588e682c0d8a02b5445eab3b61e5530c9a32db3527698cb963669b27527";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/l/lame/libmp3lame0_3.100-6_amd64.deb";
      hash = "sha256:b1292c749172e7623547ecf684da57d3ec6ca22109f08b11bbb9e6be6e6beb95";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/liba/libasyncns/libasyncns0_0.8-6%2bb3_amd64.deb";
      hash = "sha256:cadaff99f4178b1f580331045621b363abaaefc994e78eecba1857774a3cead2";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libb/libbsd/libbsd0_0.11.7-2_amd64.deb";
      hash = "sha256:bb31cc8b40f962a85b2cec970f7f79cc704a1ae4bad24257a822055404b2c60b";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libf/libffi/libffi-dev_3.4.4-1_amd64.deb";
      hash = "sha256:89fb890aee5148f4d308a46cd8980a54fd44135f068f05b38a6ad06800bf6df3";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libn/libnsl/libnsl-dev_1.3.0-2_amd64.deb";
      hash = "sha256:bb81a188c119cd7fdebae723cbc95887b6c549b2fe4fb7e268a9c8846444da99";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libn/libnsl/libnsl2_1.3.0-2_amd64.deb";
      hash = "sha256:c0d83437fdb016cb289436f49f28a36be44b3e8f1f2498c7e3a095f709c0d6f8";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libo/libogg/libogg0_1.3.5-3_amd64.deb";
      hash = "sha256:f67acb0477aed0354f411172e37af338f3ac6bd4f3766134a2cf5539884b5a28";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libs/libselinux/libselinux1-dev_3.4-1%2bb6_amd64.deb";
      hash = "sha256:efd67cd1c09a19bb1f33a53bfa30e703cecee0345f66ba727a7cc64c34656206";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libs/libsepol/libsepol-dev_3.4-2.1_amd64.deb";
      hash = "sha256:c3822443d3c829727813f8c84746506944deff1f5f2dd4fb00f90bb5929ffa89";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libs/libsndfile/libsndfile1_1.2.0-1_amd64.deb";
      hash = "sha256:d59a0b4375f0a79a08e1d4995ccfeff176c5711e5e7794bac82f117798e1a706";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libt/libtirpc/libtirpc-common_1.3.3%2bds-1_all.deb";
      hash = "sha256:3e3ef129b4bf61513144236e15e1b4ec57fa5ae3dc8a72137abdbefb7a63af85";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libt/libtirpc/libtirpc-dev_1.3.3%2bds-1_amd64.deb";
      hash = "sha256:03326473eed54ffa27efae19aa5d6aeb402930968f869f318445513093691d55";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libt/libtirpc/libtirpc3_1.3.3%2bds-1_amd64.deb";
      hash = "sha256:2a46d5a5e9486da11ffeff5740931740d6deae4f92cd6098df060dc5dff1e1c7";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libv/libvorbis/libvorbis0a_1.3.7-1_amd64.deb";
      hash = "sha256:01c14f9d1109650077a4c5c337c285476a6932d4d448f5a190c2b845724dbf21";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libv/libvorbis/libvorbisenc2_1.3.7-1_amd64.deb";
      hash = "sha256:75dd4d6f904c7db82f5112e60d8efea9e81dfedf94e970c5da7af2b3d81643c0";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libx/libx11/libx11-6_1.8.4-2%2bdeb12u2_amd64.deb";
      hash = "sha256:d88c973e79fd9b65838d77624142952757e47a6eb1a58602acf0911cf35989f4";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libx/libx11/libx11-data_1.8.4-2%2bdeb12u2_all.deb";
      hash = "sha256:987a848aeb1c358e4186368871b0526f10bb14c6b53214ab3bf8b69abb830191";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libx/libx11/libx11-xcb1_1.8.4-2%2bdeb12u2_amd64.deb";
      hash = "sha256:f5da45e1d881a793250a96613f28c471a248877f1a0f18a5c90e2a620a76c898";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libx/libxau/libxau6_1.0.9-1_amd64.deb";
      hash = "sha256:679db1c4579ec7c61079adeaae8528adeb2e4bf5465baa6c56233b995d714750";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libx/libxcb/libxcb1_1.15-1_amd64.deb";
      hash = "sha256:fdc61332a3892168f3cc9cfa1fe9cf11a91dc3e0acacbc47cbc50ebaa234cc71";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libx/libxcrypt/libcrypt-dev_4.4.33-2_amd64.deb";
      hash = "sha256:81ccd29130f75a9e3adabc80e61921abff42f76761e1f792fa2d1bb69af7f52f";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/libx/libxdmcp/libxdmcp6_1.1.2-3_amd64.deb";
      hash = "sha256:ecb8536f5fb34543b55bb9dc5f5b14c9dbb4150a7bddb3f2287b7cab6e9d25ef";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/m/media-types/media-types_10.0.0_all.deb";
      hash = "sha256:aaa46dcb3b39948ae2e0fdb72cfcb2f48c0b59f19785a3da8045c05eb19955dd";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/m/mpg123/libmpg123-0_1.31.2-1%2bdeb12u1_amd64.deb";
      hash = "sha256:a10ad0d59995b859797a5f20d2833672051d0b2c7dab4c71f2e79258b2e3f631";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/o/opus/libopus0_1.3.1-3_amd64.deb";
      hash = "sha256:c172e212f9039e741916aa8e12f3670d1e049dc0c16685325641288c2d83faa7";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/pcre2/libpcre2-16-0_10.42-1_amd64.deb";
      hash = "sha256:53892097cf102ecd8f133ccd3f1f6be6f288c6ffeeeacf6ce081dfee15292675";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/pcre2/libpcre2-32-0_10.42-1_amd64.deb";
      hash = "sha256:cadd2941b89f3f80dd739df457f96cd7a77f364d878b5c2c354130208bd60c31";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/pcre2/libpcre2-dev_10.42-1_amd64.deb";
      hash = "sha256:f0ff485a26daae8f742a1566426f0d98f06cdaf19ee0cc24764e09eff1c99257";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/pcre2/libpcre2-posix3_10.42-1_amd64.deb";
      hash = "sha256:904e16de97e0b8f4b714774fa7dc566afa4b01ad6f4c5bac4cacd024d04823de";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/pkgconf/libpkgconf3_1.8.1-1_amd64.deb";
      hash = "sha256:da01fb901123ae498c36387a32240e09e1f2866810146c5a574273f7eaf31093";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/pkgconf/pkg-config_1.8.1-1_amd64.deb";
      hash = "sha256:312b2bdeff4671f8e0d589c124554890e944dd083061e9ad6f129bc76a970765";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/pkgconf/pkgconf_1.8.1-1_amd64.deb";
      hash = "sha256:4e3ce982b5fedc6c6119268435504a64f5ffcc6d93aaecaea902d816eba1215f";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/pkgconf/pkgconf-bin_1.8.1-1_amd64.deb";
      hash = "sha256:8fb5a8f83e46ad04b4cf02651ceec56c0611a335cf0d30780d859a95d0400174";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/procps/libproc2-0_4.0.2-3_amd64.deb";
      hash = "sha256:e82ba5d01929eafb8b9954606a3c38b0332a987c2b3432388b4ee7365e54deae";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/procps/procps_4.0.2-3_amd64.deb";
      hash = "sha256:d9d0e75779cb79af869181f17b93c5c263a2b89cac6a0193c436160a4483ddc1";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/pulseaudio/libpulse-dev_16.1%2bdfsg1-2%2bb1_amd64.deb";
      hash = "sha256:835c3b0bb4353830cbede89c5827423d081c8c70617e2747beb6be2bf793e07f";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/pulseaudio/libpulse-mainloop-glib0_16.1%2bdfsg1-2%2bb1_amd64.deb";
      hash = "sha256:adb9309bc4418b7c67c6bf97fa22bc9efc26c0659e21e1c79abad66fc11b76b1";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/pulseaudio/libpulse0_16.1%2bdfsg1-2%2bb1_amd64.deb";
      hash = "sha256:7b2c5403cb726312219aad678becc6d6adcee1d8694fdffce0b6ec15ae010831";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/python3-defaults/libpython3-stdlib_3.11.2-1%2bb1_amd64.deb";
      hash = "sha256:4e58891d5c951a1e360ed9eaa814413cb5e84deadce3f08e801ac680434c786e";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/python3-defaults/python3_3.11.2-1%2bb1_amd64.deb";
      hash = "sha256:33f6dafbd1a6902d9063172ec7dbd4b2225e12009e0d7ec5c933a72c2f5f3b74";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/python3-defaults/python3-minimal_3.11.2-1%2bb1_amd64.deb";
      hash = "sha256:30f9618670e686d781afbfc713eb0830c29d2819e9cb2a0488800dad6bb99faa";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/python3-stdlib-extensions/python3-distutils_3.11.2-3_all.deb";
      hash = "sha256:a620b555f301860a08e30534c7e6f7d79818e5e1977bfec39a612e7003074318";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/python3-stdlib-extensions/python3-lib2to3_3.11.2-3_all.deb";
      hash = "sha256:4e7f5e01e49a0622d10db3d0995666a6ead6a369cd127a996e9a4f9e91696a51";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/python3.11/libpython3.11-minimal_3.11.2-6%2bdeb12u6_amd64.deb";
      hash = "sha256:b21639516f96bde030d9548220952ad17ed5dd602b6339ce183658c5aa4c1fb4";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/python3.11/libpython3.11-stdlib_3.11.2-6%2bdeb12u6_amd64.deb";
      hash = "sha256:409f354d3d5d5b605a5d2d359936e6c2262b6c8f2bb120ec530bc69cb318fac4";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/python3.11/python3.11_3.11.2-6%2bdeb12u6_amd64.deb";
      hash = "sha256:79a26e38eba4ed58f03cf606d08c4d5a6201a36b9f7c51a137685078e9644de7";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/p/python3.11/python3.11-minimal_3.11.2-6%2bdeb12u6_amd64.deb";
      hash = "sha256:4742c49d9bc418eac8c60216af4b9280440f86d5ecf0816931fcc6774a6d90d4";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/r/readline/libreadline8_8.2-1.3_amd64.deb";
      hash = "sha256:e02ebbd3701cf468dbf98d6d917fbe0325e881f07fe8b316150c8d2a64486e66";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/r/readline/readline-common_8.2-1.3_all.deb";
      hash = "sha256:69317523fe56429aa361545416ad339d138c1500e5a604856a80dd9074b4e35c";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/r/rpcsvc-proto/rpcsvc-proto_1.4.3-1_amd64.deb";
      hash = "sha256:32ac0692694f8a34cc90c895f4fc739680fb2ef0e2d4870a68833682bf1c81a3";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/s/sqlite3/libsqlite3-0_3.40.1-2%2bdeb12u1_amd64.deb";
      hash = "sha256:f152f8a4c4c78bf5762e324bcdabd18a7211944a928435ff270ad337a27aaa5f";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/u/util-linux/libblkid-dev_2.38.1-5%2bdeb12u3_amd64.deb";
      hash = "sha256:c0ca156af47937b94da0b3dc7c6df45d3a054068c2fb56b63bf0531b67429615";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/u/util-linux/libmount-dev_2.38.1-5%2bdeb12u3_amd64.deb";
      hash = "sha256:697afed24fbad876b86efe5104f0b5303a6394b9d0227682992654232a13fd4f";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/u/util-linux/uuid-dev_2.38.1-5%2bdeb12u3_amd64.deb";
      hash = "sha256:d66c5719adc05b6f5cbac926e093846c865f0b1a2095e6d781df8a7ce1f34cbf";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/z/zlib/zlib1g-dev_1.2.13.dfsg-1_amd64.deb";
      hash = "sha256:f9ce531f60cbd5df37996af9370e0171be96902a17ec2bdbd8d62038c354094f";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian-security/pool/updates/main/l/linux/linux-libc-dev_6.1.140-1_amd64.deb";
      hash = "sha256:f60f122accb0ddaa348e3345d16816278d85ba99fa41b0a2395212d5f3e08729";
    })
  ];
  run = imageTools.installDEBs;
  newLayerHash = "sha256-DIRp4qjn4e750CSgCX31cjKam1V11n7G2Gby7QKymqs=";
}
