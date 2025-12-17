{ fetchurl, stamp }:

stamp.patch {
  name = "stamp-img-skaia-steamcmd";
  entrypoint = ["dumb-init"];
  cmd = ["./steamcmd.sh"];
  base = stamp.installDebianPkgs {
    pkgs = [
      # wine32:i386
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/a/alsa-lib/libasound2_1.2.8-1%2bb1_amd64.deb";
        hash = "sha256:44c77b076a7b11ae99712439022d822245b1994c435da564ebd320bb676faf4c";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/a/alsa-lib/libasound2-data_1.2.8-1_all.deb";
        hash = "sha256:fe0780d2d3674b2977e0acb0d48b448ad72ba1642564b7dc537f55e839984c2d";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/a/alsa-topology-conf/alsa-topology-conf_1.2.5.1-2_all.deb";
        hash = "sha256:1e4503ae66ad9cbe2a024ec403cb453af07ff1d07a62e795aab24539a307ad8a";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/a/alsa-ucm-conf/alsa-ucm-conf_1.2.8-1_all.deb";
        hash = "sha256:abc7ac211bde60fb90fae9f8dc3f207818d6faadb4b3f76037785235f9284e67";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/a/apparmor/libapparmor1_3.0.8-3_amd64.deb";
        hash = "sha256:4b79f49eafc2017374da9ec206b5495433eadd2b1ea078c3895c99e72825e9d3";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/a/argon2/libargon2-1_0%7e20171227-0.3%2bdeb12u1_amd64.deb";
        hash = "sha256:4a8155b06270b88eed34d132acfc8ccc0b85499e1c4bfd7f31f8b199af42b1de";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/c/cryptsetup/libcryptsetup12_2.6.1-4%7edeb12u2_amd64.deb";
        hash = "sha256:b9a607c219be5ef04bc0fcfaec3752d9a1ba07df8d3bb2aed9bf348f90d1b6cc";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/d/dbus/dbus_1.14.10-1%7edeb12u1_amd64.deb";
        hash = "sha256:35932ffdc1ae80348e93c1263c504e62cae8a2a1476f1541ef63a9cc0a271ef9";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/d/dbus/dbus-bin_1.14.10-1%7edeb12u1_amd64.deb";
        hash = "sha256:7273d6f5ddcafa6bc81e319997f60e9b511a92c4414c1d4ecb05cba9e755da57";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/d/dbus/dbus-daemon_1.14.10-1%7edeb12u1_amd64.deb";
        hash = "sha256:d35e43de83f7df870196d292a60a56d320c47ce503bc586b30e47a192090302e";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/d/dbus/dbus-session-bus-common_1.14.10-1%7edeb12u1_all.deb";
        hash = "sha256:b19cb8e3581d6b09ff3f46fee23de2813811353228c666c9d1ad885598062e43";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/d/dbus/dbus-system-bus-common_1.14.10-1%7edeb12u1_all.deb";
        hash = "sha256:2111d3d0c98ac68ee973274058447e6fab1c359fec1d4bb195f5fcc5833a19e2";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/d/dbus/dbus-user-session_1.14.10-1%7edeb12u1_amd64.deb";
        hash = "sha256:4c3aaad251f876214fadb5580dd5f4925f73838832135e6d1dab981eb963be6b";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/d/dbus/libdbus-1-3_1.14.10-1%7edeb12u1_amd64.deb";
        hash = "sha256:18ee0ce5fab9f7b671e87da1e9fa18660e36e04a3402f24bdb8635e0ba1d35f6";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/d/dconf/dconf-gsettings-backend_0.40.0-4_amd64.deb";
        hash = "sha256:790a8ad2a229b378bbda7a0f32d9d8a522c986b08c556210c0514978ad88e356";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/d/dconf/dconf-service_0.40.0-4_amd64.deb";
        hash = "sha256:2650490642fb7e66da94943d381cea277cb811e3a4aadb6386fcd402a8390759";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/d/dconf/libdconf1_0.40.0-4_amd64.deb";
        hash = "sha256:d438bb2e3b5afaee2a90bb3fb541dcd2e47eefbc43994b5d0461c18648741e36";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/e/expat/libexpat1_2.5.0-1%2bdeb12u2_amd64.deb";
        hash = "sha256:2255e62fc22a86d2c544b8a3f516da9aee19383ad5742722ab4ce7f66a30dbc8";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/f/fontconfig/fontconfig_2.14.1-4_amd64.deb";
        hash = "sha256:010e57c24a983eecc39aab8a84219a716c10901e03bacd1927331388656f890f";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/f/fontconfig/fontconfig-config_2.14.1-4_amd64.deb";
        hash = "sha256:281c66e46b95f045a0282a6c7a03b33de0e9a08d016897a759aaf4a04adfddbe";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/f/fontconfig/libfontconfig1_2.14.1-4_amd64.deb";
        hash = "sha256:16ee38d374e064f534116dc442b086ef26f9831f1c0af7e5fb4fe4512e700649";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/f/fonts-dejavu/fonts-dejavu-core_2.37-6_all.deb";
        hash = "sha256:8892669e51aab4dc56682c8e39d8ddb7d70fad83c369344e1e240bf3ca22bb76";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/f/fonts-liberation/fonts-liberation_1.07.4-11_all.deb";
        hash = "sha256:efd381517f958b01969343634ffcbdd60056be7779af84c6f53a005090430204";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/f/freetype/libfreetype6_2.12.1%2bdfsg-5%2bdeb12u4_amd64.deb";
        hash = "sha256:8043e479f73f29992d652e3f9dfe8b17f9780c7ea6330afe379ec5f9f188ac44";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gdk-pixbuf/libgdk-pixbuf-2.0-0_2.42.10%2bdfsg-1%2bdeb12u2_amd64.deb";
        hash = "sha256:a6f8279c7f5e3ddf21176b7daaaec9bbce9e3fb9b93615673264003f5a3910cc";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gdk-pixbuf/libgdk-pixbuf2.0-bin_2.42.10%2bdfsg-1%2bdeb12u2_amd64.deb";
        hash = "sha256:958339a3f5a72aed466d85a45fe423bbc229e52613aa954cabef5d826d1139cb";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gdk-pixbuf/libgdk-pixbuf2.0-common_2.42.10%2bdfsg-1%2bdeb12u2_all.deb";
        hash = "sha256:a684020e5a0208b5059d32dbc3d64ac18b083c6424cd0ca930fcdc4737e7fd8b";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/glib-networking/glib-networking_2.74.0-4_amd64.deb";
        hash = "sha256:4c48b62bc51174e42ea652dc7d84b8d1ec4c1b4199e407afa574606f5c72d23b";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/glib-networking/glib-networking-common_2.74.0-4_all.deb";
        hash = "sha256:dba293c55191dae0819297439d642fd39b6b6d7fb90bd3f5078d84ba2213dc35";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/glib-networking/glib-networking-services_2.74.0-4_amd64.deb";
        hash = "sha256:f9145a31013193c1ceebebbd986c4817caecf90787dc394b64b49104de965287";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/glib2.0/libglib2.0-0_2.74.6-2%2bdeb12u7_amd64.deb";
        hash = "sha256:715d4dbc3e324534b5317e2ed2c78f69aa45b6b7b720dc76e7fa8ff2621bff81";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/glib2.0/libglib2.0-data_2.74.6-2%2bdeb12u7_all.deb";
        hash = "sha256:15f9df98b5eda9b03fb0c9d67a54b63740126771defd8038245dca29b2a3584f";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gsettings-desktop-schemas/gsettings-desktop-schemas_43.0-1_all.deb";
        hash = "sha256:15cc7142c3ddea0551b834c53c4d3b5cd8f5485e695100966877f2be50def7af";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/i/icu/libicu72_72.1-3%2bdeb12u1_amd64.deb";
        hash = "sha256:f7f6f99c6d7b025914df2447fc93e11d22c44c0c8bdd8b6f36691c9e7ddcef88";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/i/iptables/libip4tc2_1.8.9-2_amd64.deb";
        hash = "sha256:f2c48b367f9ec13f9aa577e7ccf81b371ce5d5fe22dddf9d7aa99f1e0bb7cfc4";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/i/iso-codes/iso-codes_4.15.0-1_all.deb";
        hash = "sha256:b1beb869303229c38288d4ddacfd582c91f594759b5767c9cecebd87f16ff70e";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/j/jbigkit/libjbig0_2.1-6.1_amd64.deb";
        hash = "sha256:6b07c77b700a615642888a82ba92a7e7c429d04b9c8669c62b2263f15c4c4059";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/j/json-c/libjson-c5_0.16-2_amd64.deb";
        hash = "sha256:d0e1ed8637d1c26b9720f6057d6355f18378bba5cc2553e459d1632783c00d70";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/k/kmod/libkmod2_30%2b20221128-1_amd64.deb";
        hash = "sha256:af63bbbfc15fbd1f254b15c393b3b95b18b18cc81348fc1b4f1c9c34b4d672d7";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/k/krb5/krb5-locales_1.20.1-2%2bdeb12u4_all.deb";
        hash = "sha256:9092b291ad699d91e8ef49137ef82ae248b8769fac6f9a756d0719740f578e07";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/l/lerc/liblerc4_4.0.0%2bds-2_amd64.deb";
        hash = "sha256:771f5c47ca69f24ca61e4be0c98c5912b182ce442f921697d17a472f3ded5c9c";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libc/libcap2/libcap2-bin_2.66-4%2bdeb12u2_amd64.deb";
        hash = "sha256:65eb89c74f863dc365088dcd061cf603d73e121b1d17fab2945bb3f292774fd0";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libc/libcap2/libpam-cap_2.66-4%2bdeb12u2_amd64.deb";
        hash = "sha256:3746846decf30cd776693d1e7852967bb79d6db74a3363b9a43a0e712bed3af7";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libd/libdeflate/libdeflate0_1.14-1_amd64.deb";
        hash = "sha256:3d4b39f94317b64a860db8a7a8b581b555124cd461fe07ec0d347edbdb9f6683";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libd/libdrm/libdrm-common_2.4.114-1_all.deb";
        hash = "sha256:32f9664138b38b224383c6986457d5ad2ec8efd559b1a0ce7749405f7a451aad";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libg/libgpg-error/libgpg-error-l10n_1.46-1_all.deb";
        hash = "sha256:8f049e9d6cf7eed3903161b13d3cc10ef1aa4bf145309b73803a8ff4fa53baa4";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libg/libgphoto2/libgphoto2-l10n_2.5.30-1_all.deb";
        hash = "sha256:77eef0b4e267f4b2bbae744ce19848b7c69416d6e25bc373b27dc00e30eb2556";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libj/libjpeg-turbo/libjpeg62-turbo_2.1.5-2_amd64.deb";
        hash = "sha256:95ec30140789a342add8f8371ed018924de51b539056522b66f207b25cba9cad";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libn/libnsl/libnsl2_1.3.0-2_amd64.deb";
        hash = "sha256:c0d83437fdb016cb289436f49f28a36be44b3e8f1f2498c7e3a095f709c0d6f8";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libp/libpng1.6/libpng16-16_1.6.39-2_amd64.deb";
        hash = "sha256:dc32727dca9a87ba317da7989572011669f568d10159b9d8675ed7aedd26d686";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libp/libproxy/libproxy1v5_0.4.18-1.2_amd64.deb";
        hash = "sha256:51885c4d67d06db094612e07b6ef729051f73b5c64793c4832372f9a4f0f6213";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libs/libsoup2.4/libsoup2.4-common_2.74.3-1%2bdeb12u1_all.deb";
        hash = "sha256:5bcfb97f0ad0dcc2ec64c22cafd71acec5c557fb8b7d1e00fdcc2db6d8742585";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libt/libthai/libthai-data_0.1.29-1_all.deb";
        hash = "sha256:eed65a75269411e47d7b393d82bc30471da5c499e9f311abbfd8c54ca1a42d9e";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libt/libtirpc/libtirpc-common_1.3.3%2bds-1_all.deb";
        hash = "sha256:3e3ef129b4bf61513144236e15e1b4ec57fa5ae3dc8a72137abdbefb7a63af85";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libt/libtirpc/libtirpc3_1.3.3%2bds-1_amd64.deb";
        hash = "sha256:2a46d5a5e9486da11ffeff5740931740d6deae4f92cd6098df060dc5dff1e1c7";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libw/libwebp/libwebp7_1.2.4-0.2%2bdeb12u1_amd64.deb";
        hash = "sha256:7259b7ce46444694ce536360ad53acb68eb3b47a7ff81d7b1b8a3939b2ac9918";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libx11/libx11-data_1.8.4-2%2bdeb12u2_all.deb";
        hash = "sha256:987a848aeb1c358e4186368871b0526f10bb14c6b53214ab3bf8b69abb830191";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxml2/libxml2_2.9.14%2bdfsg-1.3%7edeb12u4_amd64.deb";
        hash = "sha256:f3bac32a5f7d32990af06713eef57664a66e98c13750fa8e007c9cbaf49b98c7";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libz/libz-mingw-w64/libz-mingw-w64_1.2.13%2bdfsg-1_all.deb";
        hash = "sha256:b9e73ca486bc2aa66da86b5724220d2dd7c8299636b1df74c3414757a2170615";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/l/lm-sensors/libsensors-config_3.6.0-7.1_all.deb";
        hash = "sha256:7f3c9fbd822858a9e30335e4a7f66c9468962eb26cd375b93bc8b789660bf02f";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/l/lvm2/dmsetup_1.02.185-2_amd64.deb";
        hash = "sha256:c73fc490b93c83550ed272de69ec96c5da30d4456b889f9e93c7fd8e53860b85";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/l/lvm2/libdevmapper1.02.1_1.02.185-2_amd64.deb";
        hash = "sha256:aaa78ca236055fedccf637eacf7bda02bf1980b2db668dccd202b04d0d2cfe04";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/m/media-types/media-types_10.0.0_all.deb";
        hash = "sha256:aaa46dcb3b39948ae2e0fdb72cfcb2f48c0b59f19785a3da8045c05eb19955dd";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/o/openldap/libldap-common_2.5.13%2bdfsg-5_all.deb";
        hash = "sha256:72a6c113801a0f307f3a9ab9fe7a7f9559d9164af990494ed2c50617a0e20452";
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
        url = "http://deb.debian.org/debian/pool/main/p/psmisc/psmisc_23.6-1_amd64.deb";
        hash = "sha256:9d02f654bdf280a6622a9b1371f7a1fa44546702d11991e438558bc259df7b69";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/p/publicsuffix/publicsuffix_20230209.2326-1_all.deb";
        hash = "sha256:791c92c681a3cefcc9721445dc8a301a1a3cb3eef40ac2c16a4d9dd9ad5a42d7";
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
        url = "http://deb.debian.org/debian/pool/main/s/shared-mime-info/shared-mime-info_2.2-1_amd64.deb";
        hash = "sha256:dd026add873483566faefebbd8779a1e5e14ab2e44682ebfe238c3828a2b936b";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/sqlite3/libsqlite3-0_3.40.1-2%2bdeb12u2_amd64.deb";
        hash = "sha256:a8d78b40e9b4e422224aeebfe0e4dfc243f6acf3532490b0c05480d4283d41e2";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/systemd/libnss-systemd_252.39-1%7edeb12u1_amd64.deb";
        hash = "sha256:f719a2d85588c47204bd1ce92b4535330d477dee2a32afba949f5b0747599375";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/systemd/libpam-systemd_252.39-1%7edeb12u1_amd64.deb";
        hash = "sha256:25b481053c3d65c1c79a6faf10d6b8003ed7a7b3566035e6d43f1d4818e0a97f";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/systemd/libsystemd-shared_252.39-1%7edeb12u1_amd64.deb";
        hash = "sha256:c99e352383e5cab7544dcee8325086aa62af7509af8523f570eb6bd15f956a85";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/systemd/systemd_252.39-1%7edeb12u1_amd64.deb";
        hash = "sha256:87ca0d1a4202108aedea053c1a0a59b28505e5c56a73b68ff43b6e385c08434a";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/systemd/systemd-sysv_252.39-1%7edeb12u1_amd64.deb";
        hash = "sha256:20a2bdb2b3c4d57cd0c3376243d6302c23a68b6c757d2d886a657c13055271a8";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/systemd/systemd-timesyncd_252.39-1%7edeb12u1_amd64.deb";
        hash = "sha256:6dcdc6c051070fbf471258d12081cb30e30d124bd73bcf9a5f320bcdc8e7f5f7";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/u/util-linux/libfdisk1_2.38.1-5%2bdeb12u3_amd64.deb";
        hash = "sha256:8af145cff6ca72529f63e0bf6d9c68c8512387e67f64e66d00e36f72bed99160";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/w/wine/fonts-wine_8.0%7erepack-4_all.deb";
        hash = "sha256:23eeae836c53966055f7fbc96d0dd77e857eed70c954525604e15c3a8217888e";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/w/wine/wine_8.0%7erepack-4_all.deb";
        hash = "sha256:79672e2f542c450fe7e7a16a930ac8787fcfa804d29c2bf37e3d33297dbe60b0";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/x/xdg-user-dirs/xdg-user-dirs_0.18-1_amd64.deb";
        hash = "sha256:581bad07fbc84d7ca180fa68cfd3480fde9cae595020bc6d41352addbdfd7300";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/x/xkeyboard-config/xkb-data_2.35.1-1_all.deb";
        hash = "sha256:28a79c61b785f403da93af58c39aed13c022032935e3e54362c6707169cfe982";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/x/xorg/x11-common_7.7%2b23_all.deb";
        hash = "sha256:fc97c2f4495eb33a77501c7960928c0d2001e5c4b2aa438f1713e2082c23bacd";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/z/zvbi/libzvbi-common_0.2.41-1_all.deb";
        hash = "sha256:d63dc9eaedbc27089551204a0b4128861175bae43cef231aca5ee6b65c4410a8";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/a/aalib/libaa1_1.4p5-50_i386.deb";
        hash = "sha256:09352391db788b57f794cbdf141b6eced7a796796538840c9678c1ca52f2401a";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/a/abseil/libabsl20220623_20220623.1-1%2bdeb12u2_i386.deb";
        hash = "sha256:a73330a99309ccaa6746709893dd2c068f6e22ef43a860ca57468cdb24abefb3";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/a/alsa-lib/libasound2_1.2.8-1%2bb1_i386.deb";
        hash = "sha256:f5257503c01bc56bf089e2f4d75c5d20a9c28fa16fd0a777aa64af8c439f50c8";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/a/alsa-plugins/libasound2-plugins_1.2.7.1-1_i386.deb";
        hash = "sha256:d1992dcc3dacf95f16796edd337597158d9f1f2f5ad4d10d5beca0aea24ca819";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/a/aom/libaom3_3.6.0-1%2bdeb12u2_i386.deb";
        hash = "sha256:e87de8ae06ba38dc5e67dcab04458d512da7bb2efdb921dfc642a57e1d3a4b02";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/a/avahi/libavahi-client3_0.8-10%2bdeb12u1_i386.deb";
        hash = "sha256:122a81fdce4bde95c13a5ffbcf6dedd41a23a637239bb445542abe7b1c32625b";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/a/avahi/libavahi-common-data_0.8-10%2bdeb12u1_i386.deb";
        hash = "sha256:398c24169d27c1d2d0f32515d3b28f23ddf08c83efb6c28bc46d49ad645c2732";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/a/avahi/libavahi-common3_0.8-10%2bdeb12u1_i386.deb";
        hash = "sha256:f529239c32fd24574df89f5f71ddf07f0a354e67e7631b3f6d329f6307915995";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/b/brotli/libbrotli1_1.0.9-2%2bb6_i386.deb";
        hash = "sha256:75b14942a601dbac638595a9d827f91c12a9f95fb7503f2dc5471fcf57bd4bc1";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/b/bzip2/libbz2-1.0_1.0.8-5%2bb1_i386.deb";
        hash = "sha256:275c8f3e8d82f0c58f286e7ec0ca3001380895906be1f1f5b4d929f4469a54a2";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/c/cairo/libcairo-gobject2_1.16.0-7_i386.deb";
        hash = "sha256:bfc9c1614bbe318ecb4dde8185b25c5b3b887c9eb7d105145ac2bd41d85a1d5f";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/c/cairo/libcairo2_1.16.0-7_i386.deb";
        hash = "sha256:f20f81f188864a3e21b496a12008d56c91802414d36cefb74dd0e20895c97c8c";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/c/cdparanoia/libcdparanoia0_3.10.2%2bdebian-14_i386.deb";
        hash = "sha256:f4d391dd80e160e2342e88cca3b2d1defb4c0f66c4d359fba573c211f4ba4069";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/c/codec2/libcodec2-1.0_1.0.5-1_i386.deb";
        hash = "sha256:c4e23b47fdc571b1114512cef327a817459cfc834b537adde2ba47715a626b3b";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/c/curl/libcurl4_7.88.1-10%2bdeb12u14_i386.deb";
        hash = "sha256:c0c25aec81c8b1226bde7411aaa62b05f52479d6160381f47b5f2ae48d68c6f5";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/c/cyrus-sasl2/libsasl2-2_2.1.28%2bdfsg-10_i386.deb";
        hash = "sha256:25ed878313d29fd1466494f81a9240182a272623bf5d1777c59ecd28108359dd";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/c/cyrus-sasl2/libsasl2-modules_2.1.28%2bdfsg-10_i386.deb";
        hash = "sha256:91b9ad77d55cff98905be6d2bf0e63713816c1e82c915e34fca7116f0ede4884";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/c/cyrus-sasl2/libsasl2-modules-db_2.1.28%2bdfsg-10_i386.deb";
        hash = "sha256:64fc05a296e61b44356aaaa741115cc15951ffdd4fad0a76a8bfac41d78c17e0";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/d/dav1d/libdav1d6_1.0.0-2%2bdeb12u1_i386.deb";
        hash = "sha256:5ca851c78211f456f25ad98a2011e9e9c631e3591e1a6032b457fa88ec55de75";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/d/db5.3/libdb5.3_5.3.28%2bdfsg2-1_i386.deb";
        hash = "sha256:8ddad41cb683c591e4d5444560bdeb628ceec3d605c66a2a17b8bcceb1cf38b7";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/d/dbus/libdbus-1-3_1.14.10-1%7edeb12u1_i386.deb";
        hash = "sha256:aaed4e79c1efdf58ee6b43d179a9cf07cd44fc5826eecfb5fcb37c96d5be6ad5";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/e/e2fsprogs/libcom-err2_1.47.0-2%2bb2_i386.deb";
        hash = "sha256:ccdcdc4211cd85ba9b70f8618c9ba42867254086f0d5c8ef7e257272b1db46a3";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/e/elfutils/libdw1_0.188-2.1_i386.deb";
        hash = "sha256:48f28edaf9e23ed61747bd2d417dc0a4b577bef85bbed28c5d07f8be8e5312c5";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/e/elfutils/libelf1_0.188-2.1_i386.deb";
        hash = "sha256:d55c01c10209b1746e6637449357d3feb3de8c8b0102d8286553a07260d718c2";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/e/expat/libexpat1_2.5.0-1%2bdeb12u2_i386.deb";
        hash = "sha256:002fa75e3acfa317aee466c83e4f709db027d25110d2c548fd9483e196e3659d";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/f/ffmpeg/libavcodec59_5.1.7-0%2bdeb12u1_i386.deb";
        hash = "sha256:912a7ff99af2236728149961e32c6d77fcb3cd3962c774c074f6f9a3511b7a21";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/f/ffmpeg/libavutil57_5.1.7-0%2bdeb12u1_i386.deb";
        hash = "sha256:f90081833d48f340475a22195f0a3144e37f020d30081f5a36157a3c194888ca";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/f/ffmpeg/libswresample4_5.1.7-0%2bdeb12u1_i386.deb";
        hash = "sha256:fa66eb53fee3c697623dbbb5635e3daa755d01d718512ae8975b802db2320ddb";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/f/flac/libflac12_1.4.2%2bds-2_i386.deb";
        hash = "sha256:b321d509ffd07118debf00ed5683a028ce13922842d7c2650598d7c60841fa5b";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/f/fontconfig/libfontconfig1_2.14.1-4_i386.deb";
        hash = "sha256:f581ad1f64c1efadd4df10bb09d7e1a036c7df0db3fde325c941a149a829216f";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/f/freetype/libfreetype6_2.12.1%2bdfsg-5%2bdeb12u4_i386.deb";
        hash = "sha256:5945f490940c8c7dd5054aa58a0fdeac5b362ce0ef648e9cce1d7b68a0914fc7";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/f/fribidi/libfribidi0_1.0.8-2.1_i386.deb";
        hash = "sha256:26edb54d5fb29820c328ca63ce597b1b6bc10439716785ab0e02412c1e9bf1b3";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gcc-12/gcc-12-base_12.2.0-14%2bdeb12u1_i386.deb";
        hash = "sha256:611c6f95b952c021a9cb3e02d8c10d0bdbf20c318be567a95fb79d8a44521844";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gcc-12/libatomic1_12.2.0-14%2bdeb12u1_i386.deb";
        hash = "sha256:4c9e99e98b0372160ffcb6ee2548ca2a8e007283b08df3395f0eeca0d2288361";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gcc-12/libgcc-s1_12.2.0-14%2bdeb12u1_i386.deb";
        hash = "sha256:56b95a550b342418f6c4765d5c9b08df2c7167134767e44f1f1bc82ced363ece";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gcc-12/libgomp1_12.2.0-14%2bdeb12u1_i386.deb";
        hash = "sha256:16a407d1a59a5f5d9bc93a906e25701f0b1c342f438f5d5f2ef11ed89f7fb646";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gcc-12/libstdc%2b%2b6_12.2.0-14%2bdeb12u1_i386.deb";
        hash = "sha256:a262f9ad4e4b4adcb6a2663051e36e6c117159b048ae7ce8d4af215e90de3e5e";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gdk-pixbuf/libgdk-pixbuf-2.0-0_2.42.10%2bdfsg-1%2bdeb12u2_i386.deb";
        hash = "sha256:685a857f0246586d432c7f2ee1d56599a6538a8c74fca18e79664c65d0131572";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/glib-networking/glib-networking_2.74.0-4_i386.deb";
        hash = "sha256:1555a81f9c3b2654455cc1c467570b61989f441d98dec856a675ea93863ed6ec";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/glib2.0/libglib2.0-0_2.74.6-2%2bdeb12u7_i386.deb";
        hash = "sha256:69b7fad80e55c9952f4631d327a30e68843807e05d018edaa239c9e22820c6a3";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/glibc/libc6_2.36-9%2bdeb12u13_i386.deb";
        hash = "sha256:cc30f1ce0a1a836ecf7d713032dad45c924ba81e3934f78bf2b8c6f827117749";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gmp/libgmp10_6.2.1%2bdfsg1-1.1_i386.deb";
        hash = "sha256:996d31008cebdda7acb16431b70b8c2021fd0da544ec643597b172b6a7707e48";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gnutls28/libgnutls30_3.7.9-2%2bdeb12u5_i386.deb";
        hash = "sha256:04ccf15ce730418ef1565b540a5af27a6c19e2a32713d09390bef51d1aab5bd5";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gpm/libgpm2_1.20.7-10%2bb1_i386.deb";
        hash = "sha256:2c664eef1a9404326c3485e5815ceaaea9bc7d6cd3ae2b24cf9affa028a6bf9c";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/graphite2/libgraphite2-3_1.3.14-1_i386.deb";
        hash = "sha256:da8855468a52ca09493d6f61c183493aa18e57d91413f2f83bd3da0e9bf35002";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gst-plugins-base1.0/gstreamer1.0-plugins-base_1.22.0-3%2bdeb12u5_i386.deb";
        hash = "sha256:6784f8bc00dbad4b768f1b43e881a0fa90bc5cf7c2bafbfbe6a81d69bd78601d";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gst-plugins-base1.0/gstreamer1.0-x_1.22.0-3%2bdeb12u5_i386.deb";
        hash = "sha256:c54e2fe2dfb45d0760f2d06ce92a63ff0d2b14afe40a418c0c10134e0d5d3e9c";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gst-plugins-base1.0/libgstreamer-plugins-base1.0-0_1.22.0-3%2bdeb12u5_i386.deb";
        hash = "sha256:bb9d26b62fbe3fff74136388dc197d81484f4c89c0ac78a13a98bd46bb72f8b0";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gst-plugins-good1.0/gstreamer1.0-plugins-good_1.22.0-5%2bdeb12u3_i386.deb";
        hash = "sha256:a0a7b423fbadf326f98a0b871dc65c218d25a9388991d71b5cbdf3ab40da5202";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/g/gstreamer1.0/libgstreamer1.0-0_1.22.0-2%2bdeb12u1_i386.deb";
        hash = "sha256:a5b8d9d3d967199c21a316a2533ee9891deb0defe4593c93d1ca569b0e5a89a6";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/h/harfbuzz/libharfbuzz0b_6.0.0%2bdfsg-3_i386.deb";
        hash = "sha256:5a997711a272459b6c174fb5a6a0b6d2ded8022ae070fad9f1b8bb226f16017e";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/h/highway/libhwy1_1.0.3-3%2bdeb12u1_i386.deb";
        hash = "sha256:be4a388141bc533c98c915104839a9e3c6d521ce0c6e2277f58bea5f4bc5d2a7";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/i/icu/libicu72_72.1-3%2bdeb12u1_i386.deb";
        hash = "sha256:4c64bdd09608dfa525f41f5988f371c32a88eab33da425c83a6d41d5b4c95501";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/i/intel-gmmlib/libigdgmm12_22.3.3%2bds1-1_i386.deb";
        hash = "sha256:99337f34f68162192272bebd89a3a0649e7c28def457a392f5526bc954d0ceab";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/i/intel-media-driver/intel-media-va-driver_23.1.1%2bdfsg1-1_i386.deb";
        hash = "sha256:311e1a6fa9de1170eb0a01f8226205e0c62f73056f7fc20907e5a39cb8ba3b8c";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/i/intel-vaapi-driver/i965-va-driver_2.4.1%2bdfsg1-1_i386.deb";
        hash = "sha256:9d634ff4ff51694db7bbc862af70593e72347dbf49efc016782ed3a7bab432d0";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/j/jackd2/libjack-jackd2-0_1.9.21%7edfsg-3_i386.deb";
        hash = "sha256:22f62cd13a4d900fd528e52eb6dc76e85e689f55c6bbb10d545321eb28a632b5";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/j/jbigkit/libjbig0_2.1-6.1_i386.deb";
        hash = "sha256:54a64993ef415f1332ee4f66552b9dd823aeb566ea19dfad1dc6cd9068cedc7c";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/j/jpeg-xl/libjxl0.7_0.7.0-10%2bdeb12u1_i386.deb";
        hash = "sha256:f9296e56ca5ba43dba5b40e693965ca11e31dbae3eb7cda5924be836562703c9";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/k/keyutils/libkeyutils1_1.6.3-2_i386.deb";
        hash = "sha256:124ebf5b8307e2182afaaa166f057144ccc7132e2391164bd86d6c493efc94ef";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/k/krb5/libgssapi-krb5-2_1.20.1-2%2bdeb12u4_i386.deb";
        hash = "sha256:7028a638e3e8059ade003831989a3060ada7a1364465ea2cd1980ea3b0ffb4d1";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/k/krb5/libk5crypto3_1.20.1-2%2bdeb12u4_i386.deb";
        hash = "sha256:d35f33ab1b80882779b65e5fc6993c28a9bb5d1f42b089cf6017f85944ac3e69";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/k/krb5/libkrb5-3_1.20.1-2%2bdeb12u4_i386.deb";
        hash = "sha256:a4c8e309f5aa27c85cbcc4de9f36cb6510989765b82d71d0a508351dabcb97c2";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/k/krb5/libkrb5support0_1.20.1-2%2bdeb12u4_i386.deb";
        hash = "sha256:b34a2bc77b9c4bfe400ebc1bc134d9aabcbf726ea1dc07e957a1ef6c1bc5fffe";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/l/lame/libmp3lame0_3.100-6_i386.deb";
        hash = "sha256:fdc9724815021ee8181e1aac46b52d1498a9d1ffc6dd98bb115b8c1dfe2ec1a3";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/l/lcms2/liblcms2-2_2.14-2_i386.deb";
        hash = "sha256:f5a3f83e8202980ef7b4231505fee650ee9aa680cbbf7c0dca79e0616df740d0";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/l/lerc/liblerc4_4.0.0%2bds-2_i386.deb";
        hash = "sha256:c966a773ef469a0a079fbfde9d58cdb88fc2cf26e91e1b5442af8bd16658603a";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/liba/libasyncns/libasyncns0_0.8-6%2bb3_i386.deb";
        hash = "sha256:de353333e0bec51306ee6b12c309693dd2108d25b69e60b70bd1c639c1376cde";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/liba/libavc1394/libavc1394-0_0.5.4-5_i386.deb";
        hash = "sha256:906ffc9c46de98c107fd982422bafbcf1b8eb3b7892cd19072bd30306ac89dfe";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/liba/libavif/libavif15_0.11.1-1%2bdeb12u1_i386.deb";
        hash = "sha256:794d8a37e70dad0e8aeb25c1e1cb2881b103947b482b482b3cf577fb5aa94436";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libb/libbsd/libbsd0_0.11.7-2_i386.deb";
        hash = "sha256:527d1696a70421227c3de01a82a3eceaeb9f78a927eac0d8a1b41924199bf48b";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libc/libcaca/libcaca0_0.99.beta20-3_i386.deb";
        hash = "sha256:3bd43134b6093a72f8f88eb857660b05db0cfe36ccc78b63a9edd155261e1597";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libc/libcap2/libcap2_2.66-4%2bdeb12u2_i386.deb";
        hash = "sha256:de674f4bdc770bd8bc5b67b0a33737efd4556d79f82fae9c0a4dcfc6390489ca";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libc/libcapi20-3/libcapi20-3_3.27-3%2bb1_i386.deb";
        hash = "sha256:d8d94c02603f1dd357ca6b430cdc95e7a2e69570962d3670d6a2ba5a14ce300f";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libd/libdatrie/libdatrie1_0.2.13-2%2bb1_i386.deb";
        hash = "sha256:f3333ceab99d9eaf3d9e8289637c19ab59d77c7cdecdf33c0f33889015acd7e3";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libd/libde265/libde265-0_1.0.11-1%2bdeb12u2_i386.deb";
        hash = "sha256:b3ee7973af4565fefa38d3e40588978b4648022e1e60675454f837ddc227380a";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libd/libdecor-0/libdecor-0-0_0.1.1-2_i386.deb";
        hash = "sha256:74b39bf96b3870899883c8e3b6a16bca75e8c5828614a7e1b9d061439ee6bb35";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libd/libdecor-0/libdecor-0-plugin-1-cairo_0.1.1-2_i386.deb";
        hash = "sha256:bc2462689f9297b4bc6b2f9c948028a8d27abfe9acce5984519d6e2085d13ccb";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libd/libdeflate/libdeflate0_1.14-1_i386.deb";
        hash = "sha256:b55625c3f1c39e3a76e545198b68e773aff4dcc94a6e41aa889a24c1f4df9ad4";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libd/libdrm/libdrm-amdgpu1_2.4.114-1%2bb1_i386.deb";
        hash = "sha256:35d99e5ace41b687384110e6c714cd48fa210e16410f290b3559f05319305f1f";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libd/libdrm/libdrm-intel1_2.4.114-1%2bb1_i386.deb";
        hash = "sha256:3114962de53247c720044dd78263aabefbcf71edb6e5c3bc0c5d20b6e15043ee";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libd/libdrm/libdrm-nouveau2_2.4.114-1%2bb1_i386.deb";
        hash = "sha256:b3ed51cf15a315a4771c7030a363fbcd113475b271d5b53fc8b596c3b3e36d39";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libd/libdrm/libdrm-radeon1_2.4.114-1%2bb1_i386.deb";
        hash = "sha256:2523ac6b4366999aade876acb846af9bcf90bac826e787c938591dda6f34813d";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libd/libdrm/libdrm2_2.4.114-1%2bb1_i386.deb";
        hash = "sha256:33846903c53e3c1a13ae366437286a9e019917f2f3467648ca510d8af31fb59e";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libd/libdv/libdv4_1.0.0-15_i386.deb";
        hash = "sha256:d1e60b5dfeda95af04a17454bb847d4d8b0eb54596e2c87b117d50709526eb09";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libe/libedit/libedit2_3.1-20221030-2_i386.deb";
        hash = "sha256:e8b738e18c73a6661601452f9689babbee2f524491a15154cbda606b7857b6f8";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libe/libexif/libexif12_0.6.24-1%2bb1_i386.deb";
        hash = "sha256:65722098f24a59f3a07cb868b7d492890a581d27b8392c4a55c91d911c5a02e3";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libf/libffi/libffi8_3.4.4-1_i386.deb";
        hash = "sha256:21b4d7de1cea73aa8d594106e473c1c6b6f33fd11cb66af5db35f9317f5f9a60";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libg/libgav1/libgav1-1_0.18.0-1%2bb1_i386.deb";
        hash = "sha256:d2ed27872ae6ad9555bf617dde8d8eb8b8a3d5350f496912a0e3ebc492c82879";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libg/libgcrypt20/libgcrypt20_1.10.1-3_i386.deb";
        hash = "sha256:94e9a2a7a14f2505b26124a0f23982d13131a9090671ac4f5e94923d2d30f942";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libg/libgd2/libgd3_2.3.3-9_i386.deb";
        hash = "sha256:b299550916f79e05d3bb9e5b4d24b1f655f48f40d877cecb475d456f325e76c1";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libg/libglvnd/libgl1_1.6.0-1_i386.deb";
        hash = "sha256:56127382186908408be0f87fa009ef6e322e0d6079fd84a4e9135de18949d6f6";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libg/libglvnd/libglvnd0_1.6.0-1_i386.deb";
        hash = "sha256:057b79f23b040f7d7fab1b5ec2d7c027c195c827b8a136d14ee2ab8a513aecf9";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libg/libglvnd/libglx0_1.6.0-1_i386.deb";
        hash = "sha256:3c7df84621b49ce93355183041c58a5540e46e35b799209a1fade10a61dfb114";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libg/libgpg-error/libgpg-error0_1.46-1_i386.deb";
        hash = "sha256:9e4109555b4971a2466bdda6fdc3ca90d47a1d0c4b8d7f11ad5720d0e0028392";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libg/libgphoto2/libgphoto2-6_2.5.30-1_i386.deb";
        hash = "sha256:ee22cfb639671abe2ae6b0cf2d9be03af5d559eddd912392fe9ec19db531559e";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libg/libgphoto2/libgphoto2-port12_2.5.30-1_i386.deb";
        hash = "sha256:be2b6827dd97ede0c41ceb7384f492003bad675260e0c3b7f308857d37a22d97";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libg/libgsm/libgsm1_1.0.22-1_i386.deb";
        hash = "sha256:44ed296d70cf04f6f6b69405db87c470ea4d43998f5adfae5f1664a28148f5b2";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libg/libgudev/libgudev-1.0-0_237-2_i386.deb";
        hash = "sha256:b4895b3b7a8e3f01b54b41469b071e3bd4f6c7577ee7429c7e141c749a58a71e";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libh/libheif/libheif1_1.15.1-1%2bdeb12u1_i386.deb";
        hash = "sha256:68780d6dd62e85b4438393ea05b2a8bca191961dc9d81accbf23ae90fef5ec0f";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libi/libidn2/libidn2-0_2.3.3-1%2bb1_i386.deb";
        hash = "sha256:49167c0ddd749810a5242b60c7e280860f4fbcb7b4ee9ee456f44d97cd5baef5";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libi/libiec61883/libiec61883-0_1.2.0-6%2bb1_i386.deb";
        hash = "sha256:c48d4bbed8fa69197d1dff30486a70695c075a352c7fa3c259d3d601a23caac6";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libj/libjpeg-turbo/libjpeg62-turbo_2.1.5-2_i386.deb";
        hash = "sha256:3c42ca19e27311d692eb97df6b42f1cedc5543896ad428562c4c226932726c00";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libm/libmd/libmd0_1.0.4-2_i386.deb";
        hash = "sha256:5416c6fcbfb73c21d1e7bf1aeeb3d7efc1d6cf7274c2332ec9d5648d04e5d0ca";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libo/libogg/libogg0_1.3.5-3_i386.deb";
        hash = "sha256:2914d7e7a37d8e82339cebc43b0b4f71b561623dceb5ebe12156837e3de86318";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libp/libpcap/libpcap0.8_1.10.3-1_i386.deb";
        hash = "sha256:63d4d9603c9f993dd5d878a06f2755601e75735ea6558080b11a743bb3dae390";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libp/libpciaccess/libpciaccess0_0.17-2_i386.deb";
        hash = "sha256:24b690b1045c2d4403103348abfba74d5d58b5e29da00b798b7bd55d0aa1e28a";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libp/libpng1.6/libpng16-16_1.6.39-2_i386.deb";
        hash = "sha256:e8a851ecd910898ab88af5bff4667f0ae6be8d6ecad3f6df3ba3b65b44a0acd9";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libp/libproxy/libproxy1v5_0.4.18-1.2_i386.deb";
        hash = "sha256:459adb17542176fa5ba547f5d37ecae810862bc2bdd6ac967999c03d7cc7a0d5";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libp/libpsl/libpsl5_0.21.2-1_i386.deb";
        hash = "sha256:cc87d9aec8ae3804bc408a38cfa73e71c5c6494474635dfc72ecc948df1abed6";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libr/libraw1394/libraw1394-11_2.1.2-2_i386.deb";
        hash = "sha256:3f0d734beec6329685ad9be4ce886e8052ae0c521f88c123de8b3e757f8f2b23";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libr/librsvg/librsvg2-2_2.54.7%2bdfsg-1%7edeb12u1_i386.deb";
        hash = "sha256:19bbbfd44c24a25960b826ca92aba40088c076a74251a688fab0844817dd97c9";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libr/librsvg/librsvg2-common_2.54.7%2bdfsg-1%7edeb12u1_i386.deb";
        hash = "sha256:027b378f499ddc7432b6c58ef96151771ed714b6f840e305d61201a8a241d032";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libs/libsamplerate/libsamplerate0_0.2.2-3_i386.deb";
        hash = "sha256:ebcdf65728c656531da45deae996b08c4ea93113427d41dc1762dd74d13a74e9";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libs/libsdl2/libsdl2-2.0-0_2.26.5%2bdfsg-1_i386.deb";
        hash = "sha256:ba21afbcaffdf4b2adc4d113fcc3e0d398d6e267e169aa304409a33e05e05fd0";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libs/libselinux/libselinux1_3.4-1%2bb6_i386.deb";
        hash = "sha256:1af838cdb8342802e3fdbf334f75c42d3027246bcec72f2c2ca26a996014f143";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libs/libshout/libshout3_2.4.6-1%2bb1_i386.deb";
        hash = "sha256:4260f63f1c33b6da39e6bd3794e7b37443a2d3edfd7c88fce77ebf91e398679c";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libs/libsndfile/libsndfile1_1.2.0-1%2bdeb12u1_i386.deb";
        hash = "sha256:6cf51c091b37c866d9a7aa0bb5011c1e93546cff6fc96827aaaf906eedc7fbd5";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libs/libsoup2.4/libsoup2.4-1_2.74.3-1%2bdeb12u1_i386.deb";
        hash = "sha256:508fa40dca896f3037db6b4de09dc14161a97287d83aa9bbb88735f47e55176b";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libs/libsoxr/libsoxr0_0.1.3-4_i386.deb";
        hash = "sha256:8c61b99ec5448bc013672a3ba615d8d04c41b74e0c2d98024344e34fecf18e54";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libs/libssh2/libssh2-1_1.10.0-3%2bb1_i386.deb";
        hash = "sha256:d7af9a5d6e33866d636a750ca647ffc52ec79f6d65726b52695e5cd0b8789250";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libt/libtasn1-6/libtasn1-6_4.19.0-2%2bdeb12u1_i386.deb";
        hash = "sha256:b21b8068b333245ddeaafd2903f55f7b986217e80e060670f21af23b19cf8a04";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libt/libthai/libthai0_0.1.29-1_i386.deb";
        hash = "sha256:b553e6c69425c0325c7193e3f41241f449c86b865bd0c0e75bee76bae81485e2";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libt/libtheora/libtheora0_1.1.1%2bdfsg.1-16.1%2bdeb12u1_i386.deb";
        hash = "sha256:7205448469c6c38d61d6d1d8bb53f2788dab93924627ca735511fda09908d63f";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libt/libtool/libltdl7_2.4.7-7%7edeb12u1_i386.deb";
        hash = "sha256:82f6171fe2adf0f50e184d7072ddb407645f0f27fc1b0cad90032680bae3317f";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libu/libunistring/libunistring2_1.0-2_i386.deb";
        hash = "sha256:04aed8ddaa8f92fcdb378bd92eb23a78bda0f3e3be59501329b1968362492781";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libu/libunwind/libunwind8_1.6.2-3_i386.deb";
        hash = "sha256:39d3ddf6f813d3137f70fc3c05f6cfb6b3ad17251430df7cef7463b1adf6d29a";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libu/libusb-1.0/libusb-1.0-0_1.0.26-1_i386.deb";
        hash = "sha256:c4e1a66b847160bd3826d5e5e66c86e0b8aafdfe9b29802831068e242080fab5";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libv/libva/libva-drm2_2.17.0-1_i386.deb";
        hash = "sha256:91a89599931d8896db6f68be1c81436a4bbd5a746d774c543d5505f6a3903d5e";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libv/libva/libva-x11-2_2.17.0-1_i386.deb";
        hash = "sha256:1e55254890ef545b8c571e1b794a56024545bf062f8f2843899889f926df9aec";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libv/libva/libva2_2.17.0-1_i386.deb";
        hash = "sha256:2aa84eea8a1e74354448cf6819e0c04a6c32c2822b3a33d7c6991c16abb55763";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libv/libva/va-driver-all_2.17.0-1_i386.deb";
        hash = "sha256:1ead38be0f9bccb409f3920c99d1ca0091414fa3b021b0df02ca7a07e3cfa9a3";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libv/libvdpau/libvdpau1_1.5-2_i386.deb";
        hash = "sha256:29f8a10b5494139eafca4e686d5919e3e69be807af8455438c40de552b212f66";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libv/libvdpau/vdpau-driver-all_1.5-2_i386.deb";
        hash = "sha256:3354f318b54ffd7b0091523f2ef4e8545dd0015d285bd4f322eaa73e4c825cbe";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libv/libvdpau-va-gl/libvdpau-va-gl1_0.4.2-1%2bb1_i386.deb";
        hash = "sha256:6da0557207c9c47bf5c1d5f88d3509fb8ad87db5b28de3658b8f15e561e4f262";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libv/libvisual/libvisual-0.4-0_0.4.0-19_i386.deb";
        hash = "sha256:a492282adda80be8463e7f6e70862e4b2e98c8f97316d1438f4fe4fd36b91d66";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libv/libvorbis/libvorbis0a_1.3.7-1_i386.deb";
        hash = "sha256:56bb3970d0a9fbf07c6d027b8ab8fecd386b47e14bce7fb3e2ac93a0abe7f7d7";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libv/libvorbis/libvorbisenc2_1.3.7-1_i386.deb";
        hash = "sha256:04de77bb41d5062f135ebebf210f8f558080a4c5b8ba9cc216883c957207fb7e";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libv/libvpx/libvpx7_1.12.0-1%2bdeb12u4_i386.deb";
        hash = "sha256:73d970fa320bd10e2ca54ed1b12722a0ea6a64aada68d50af7f7246e93b16bd6";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libw/libwebp/libwebp7_1.2.4-0.2%2bdeb12u1_i386.deb";
        hash = "sha256:b596ae0e0f830a514e3b26451b2c3404074ed3cc677799a588c0ed38952db4e8";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libw/libwebp/libwebpmux3_1.2.4-0.2%2bdeb12u1_i386.deb";
        hash = "sha256:4f885f3e8d3d49694b4f67f2eabf30cb352cfdd666da40e98329a253a7a16084";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libx11/libx11-6_1.8.4-2%2bdeb12u2_i386.deb";
        hash = "sha256:df42dab90a6f0d064ba0aa9f0857056021b1d0c37c82ac495b83a953a5e52799";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libx11/libx11-xcb1_1.8.4-2%2bdeb12u2_i386.deb";
        hash = "sha256:4d96d62f7204767e68d936648c70e717f6d5915b03f74ee159140111dbd0062c";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxau/libxau6_1.0.9-1_i386.deb";
        hash = "sha256:3003e98e7ecef061ec2f1df1fc106f55b9c051469bc2ab4be743b85851ea7d25";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxcb/libxcb-dri2-0_1.15-1_i386.deb";
        hash = "sha256:035ee3f61661486fa13927a19120de9ddfb08694781db055b113384c8da05e9d";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxcb/libxcb-dri3-0_1.15-1_i386.deb";
        hash = "sha256:2142f830d1d7ab016f79e026a13100f6622e113405402a2e02d9dea0ba381e41";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxcb/libxcb-glx0_1.15-1_i386.deb";
        hash = "sha256:46baab50fae8c6c2c5ce4413c5d81f8710d75cc92e84c43903f83a8039928e51";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxcb/libxcb-present0_1.15-1_i386.deb";
        hash = "sha256:6160f8121510d59d5b1c1fc7d94695954272205b577dbcf82037c936b40f1974";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxcb/libxcb-randr0_1.15-1_i386.deb";
        hash = "sha256:d8b9bfb75a1ce0dfa822c06ba62c9db9b995557d8a0f070542690362869ca94a";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxcb/libxcb-render0_1.15-1_i386.deb";
        hash = "sha256:11addf305dc9ac23c78694517b272f6b4dee6d2e9d89497f1da6221fd93e92c6";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxcb/libxcb-shm0_1.15-1_i386.deb";
        hash = "sha256:c9071375b6e4b672cef68cef9dc6b4fe35fcca1424d1a544a027589aa9dc37b4";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxcb/libxcb-sync1_1.15-1_i386.deb";
        hash = "sha256:100459b1552d17ed5a32e02d1ef8f6c16814c64a656980155744382fe5b454e9";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxcb/libxcb-xfixes0_1.15-1_i386.deb";
        hash = "sha256:a2cd10b18bce111a6ebd7a4a1737e35e50cf2c7dd76cd0fed9be5b0f2248063e";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxcb/libxcb1_1.15-1_i386.deb";
        hash = "sha256:58eac13b8d4614a9804b8fbfd8090a4da725ee70ebda435cb807144348d8a216";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxcomposite/libxcomposite1_0.4.5-1_i386.deb";
        hash = "sha256:0ee1b09337cd00581f2923170be8d0334f60614edfd2b0754b9aef7e0d087178";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxcursor/libxcursor1_1.2.1-1_i386.deb";
        hash = "sha256:6a9b8a2db0884bc2e8335a845433ee7bebace56621d3c65f7134578c455d587c";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxdamage/libxdamage1_1.1.6-1_i386.deb";
        hash = "sha256:a070323379f77a7712a4070cc0bba7756ca8012d11519b463a9f5c7a8e182c35";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxdmcp/libxdmcp6_1.1.2-3_i386.deb";
        hash = "sha256:186935868181faae5f7956ab250a7a135b28d139d163a575050ad31bbfd56e33";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxext/libxext6_1.3.4-1%2bb1_i386.deb";
        hash = "sha256:ebb222c1d9c1fbb98d1663e8f18f7b9fd4747133494cec8c566a86037c5f26cf";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxfixes/libxfixes3_6.0.0-2_i386.deb";
        hash = "sha256:35539777d881fbff6f93a71571fb065932efa1bf2392cc3a19b33df996352249";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxi/libxi6_1.8-1%2bb1_i386.deb";
        hash = "sha256:bd083eb583445cc13138520ce8b0753bed467bf9582eb75a286615a2833c4aa9";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxinerama/libxinerama1_1.1.4-3_i386.deb";
        hash = "sha256:8640bf38f7c6f948eb88a94ac6192c6b726506fa6e2316b0b061fde3e00d0154";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxkbcommon/libxkbcommon0_1.5.0-1_i386.deb";
        hash = "sha256:9fa31632c7e6fdb3e1389d54648f09bacd209ce319f61449c20c6680a2db7b59";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxml2/libxml2_2.9.14%2bdfsg-1.3%7edeb12u4_i386.deb";
        hash = "sha256:59779f6b7e2aaa384f7aa661c196f5f358f46e7196130f408b1ebf7b674a3112";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxpm/libxpm4_3.5.12-1.1%2bdeb12u1_i386.deb";
        hash = "sha256:62b0c9721c00484db846829c83bce3fb6589df2915ef2cce6b8db4bce1b32528";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxrandr/libxrandr2_1.5.2-2%2bb1_i386.deb";
        hash = "sha256:1f619d4db7107c0c6344183e5e0254c6ee8d4da74d7ee46f52cdef327354fd4b";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxrender/libxrender1_0.9.10-1.1_i386.deb";
        hash = "sha256:5368cbe5f3a78f6518e156536676c3acd7d596d45612c23c1c4bd04f1886e6c7";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxshmfence/libxshmfence1_1.3-1_i386.deb";
        hash = "sha256:828d6a5e40fd9d084770b25ddf37d3e688e0aa7c4e4079913f225d7bb25a33e2";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxss/libxss1_1.2.3-1_i386.deb";
        hash = "sha256:eb50d23f8e849a7f86a6313f3e48c5c1fbf6cf82ca34ea5ef32bc99ae980c64a";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxv/libxv1_1.0.11-1.1_i386.deb";
        hash = "sha256:0d8fe362c08e3254fb5451fbc5dd9d1d51592e7ed028f6d5183431dbecbc3302";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libx/libxxf86vm/libxxf86vm1_1.1.4-1%2bb2_i386.deb";
        hash = "sha256:42f33f431d669d23cdb5912e804f6a694200b4ea51fca6ca283c6a5804a0f9dc";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/liby/libyuv/libyuv0_0.0%7egit20230123.b2528b0-1_i386.deb";
        hash = "sha256:3e26086ac15f3f579eb55ac04d33d47ac190c3b519e269956fc621d01927120b";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/libz/libzstd/libzstd1_1.5.4%2bdfsg2-5_i386.deb";
        hash = "sha256:b9009648837c1fa095ca3b79eec3e6358df3946dd0a70c0f66ec3558695af8d5";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/l/llvm-toolchain-15/libllvm15_15.0.6-4%2bb1_i386.deb";
        hash = "sha256:b892bb1c7c88498f280524917740174cb8d8fab147f682911c8574a3feebac80";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/l/lm-sensors/libsensors5_3.6.0-7.1_i386.deb";
        hash = "sha256:fd15c95bacd6dfd3cb389296079a9a9abfd66b60af7aed674fe179db2ada869b";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/l/lz4/liblz4-1_1.9.4-1_i386.deb";
        hash = "sha256:6ca34fa9139be02a118dd22b969f34018fc4628b02acd1d21c4621d16057ac6a";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/m/mesa/libgbm1_22.3.6-1%2bdeb12u1_i386.deb";
        hash = "sha256:691b34b52b1168bdd412df4ea94dd831dbafdba4e862638c986c03dcfe9c2212";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/m/mesa/libgl1-mesa-dri_22.3.6-1%2bdeb12u1_i386.deb";
        hash = "sha256:725bfed75f1663655d55474be87b3d6fee9429cb3e86578c5942dd129928f127";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/m/mesa/libglapi-mesa_22.3.6-1%2bdeb12u1_i386.deb";
        hash = "sha256:63c8ac3ac34cc8d168a38fd95e83f8ca19816c274df3dbe5e4d36cce15444d08";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/m/mesa/libglx-mesa0_22.3.6-1%2bdeb12u1_i386.deb";
        hash = "sha256:090250cf0ac189ede2587c9cdecd2a61d6639c8345ab68f95db9c26996088e00";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/m/mesa/libosmesa6_22.3.6-1%2bdeb12u1_i386.deb";
        hash = "sha256:3cd5b705452de3fc595264f6d8c10310556cca7347ca74c6e2f77dadb2322ed4";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/m/mesa/mesa-va-drivers_22.3.6-1%2bdeb12u1_i386.deb";
        hash = "sha256:64beb31714828193e166b15270a31ca289aefde22e9208f6ee6e26c11641ebec";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/m/mesa/mesa-vdpau-drivers_22.3.6-1%2bdeb12u1_i386.deb";
        hash = "sha256:6380397cb65841a4a8498c78b55b62e753733e09ff208295c79c94322bbb0e5a";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/m/mesa/mesa-vulkan-drivers_22.3.6-1%2bdeb12u1_i386.deb";
        hash = "sha256:c91cbc73717261540b15c2cdf974462e0b7a5db30de6ffe8031c3f89437b374d";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/m/mpg123/libmpg123-0_1.31.2-1%2bdeb12u1_i386.deb";
        hash = "sha256:7a7c29b2882a05610f89091ceff67773ec79d6558294226c1905b0a833430428";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/n/ncurses/libncurses6_6.4-4_i386.deb";
        hash = "sha256:6e10d1c6e653f0f70ebd7703715988c755195715a70d6965832650acb75355ee";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/n/ncurses/libncursesw6_6.4-4_i386.deb";
        hash = "sha256:9e453156a8a8374f64402ce7e4d4e15c65bf7186534530b39210ff68936aa020";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/n/ncurses/libtinfo6_6.4-4_i386.deb";
        hash = "sha256:d6de1d8daeadda8ba57f86d42273919fba9e57f699036b7c51062d91778f4a16";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/n/nettle/libhogweed6_3.8.1-2_i386.deb";
        hash = "sha256:d54aad2cf3e5104c80a2ed03511f7502558607df5d535f77e441e13bb26e01a8";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/n/nettle/libnettle8_3.8.1-2_i386.deb";
        hash = "sha256:3e928be29ce533c1e2d9e1bdf520a2925688b01b329533e71551ebfab7f6a402";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/n/nghttp2/libnghttp2-14_1.52.0-1%2bdeb12u2_i386.deb";
        hash = "sha256:71e7b6feebeafb0fc679fbc1922fefaee29c1f5e14098e21f9b2e10d474314e2";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/n/numactl/libnuma1_2.0.16-1_i386.deb";
        hash = "sha256:659aafdccfbcf061f79c8bc0b3658b0c57cff0d5117fb06ad82937403b7e99e9";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/o/ocl-icd/ocl-icd-libopencl1_2.3.1-1_i386.deb";
        hash = "sha256:18be5fb67320c3b7f699b14826d6ca6fd70662d150a3945a6be180e4018ae0a5";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/o/openjpeg2/libopenjp2-7_2.5.0-2%2bdeb12u2_i386.deb";
        hash = "sha256:49cd1f892f9a0313855c052abc6c37b46ec139568ef9493be64cdefa5a69328c";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/o/openldap/libldap-2.5-0_2.5.13%2bdfsg-5_i386.deb";
        hash = "sha256:d295b402f242bb0e11524e02d7bdf98d77da3970f409f2c4924ced3a41bcbca9";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/o/opus/libopus0_1.3.1-3_i386.deb";
        hash = "sha256:eec578cb2f9e67fdbd08ee21d187f19ae6698494dfc46e71d2f7ba231d561f71";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/o/orc/liborc-0.4-0_0.4.33-2_i386.deb";
        hash = "sha256:60f4342f9ddd8b65de91bb7c66fb8c711b04db8ba309aadb04a91bc023b29c52";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/p/p11-kit/libp11-kit0_0.24.1-2_i386.deb";
        hash = "sha256:f8e5a6f2201eb0317e6149ec95fc08e5c6879fe1247e729e0635dfd9c9f063b3";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/p/pango1.0/libpango-1.0-0_1.50.12%2bds-1_i386.deb";
        hash = "sha256:786aa29d90d330fd5cd7f10e145d77b3bdf75175ed895afe1efbc8fb7836bd8e";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/p/pango1.0/libpangocairo-1.0-0_1.50.12%2bds-1_i386.deb";
        hash = "sha256:7462f08820dc4d81ea873eea4cc9c5a5cb6a344ed85255a4c697fb676c38237d";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/p/pango1.0/libpangoft2-1.0-0_1.50.12%2bds-1_i386.deb";
        hash = "sha256:afdd5026de7976dc86043117c4b515e15566da2a45ee3093231be7e5c4e048ac";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/p/pcre2/libpcre2-8-0_10.42-1_i386.deb";
        hash = "sha256:f5485ecd3a5ba7bdb7de1cb502165f20fd7e1f7b9a4988ab7bdb89c58aa1596b";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/p/pixman/libpixman-1-0_0.42.2-1_i386.deb";
        hash = "sha256:bc4bf4f18077e520d676c7fd18b4ae61a39617ca0aba6af4fd2aba735c1f13d0";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/p/pulseaudio/libpulse0_16.1%2bdfsg1-2%2bb1_i386.deb";
        hash = "sha256:fc8cac04e3cd077b70f94eb1fd6cd42b4c5f7aae27cda7bc0c5bcea307537056";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/r/rtmpdump/librtmp1_2.4%2b20151223.gitfa8646d.1-2%2bb2_i386.deb";
        hash = "sha256:1bf3dcb8f2a7c1cff745214e529f93b3353a863f3334e3938aaae25e8a29a9bb";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/r/rust-rav1e/librav1e0_0.5.1-6_i386.deb";
        hash = "sha256:96feeab327bb2c2d522d04e667312375b1213c6df5c5aa2b7822b0da3134a7b7";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/shine/libshine3_3.1.1-2_i386.deb";
        hash = "sha256:5cbb5e4e204ab53438839a0b8b01744187b64688b037f6d216e6039432986c60";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/slang2/libslang2_2.3.3-3_i386.deb";
        hash = "sha256:63693198ea4c08e2e28a454eff52e763e4a6fad8bc1821de3baa1217ad85bfe8";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/snappy/libsnappy1v5_1.1.9-3_i386.deb";
        hash = "sha256:231b389ecf112c439ff6d62454eea82c0a7ed4519d48bac49ec94e5569c042e6";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/speex/libspeex1_1.2.1-2_i386.deb";
        hash = "sha256:aab86f940453c6df5b0b3c0df33f4ded8620697671efd38e5f8839d6482b3146";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/speexdsp/libspeexdsp1_1.2.1-1_i386.deb";
        hash = "sha256:267fda1103d2c5e19dbed7b9737cd5ba207940980b7c6ccbb62f264c151790fe";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/sqlite3/libsqlite3-0_3.40.1-2%2bdeb12u2_i386.deb";
        hash = "sha256:8b96faa7a4a16a24576dd034a10e0cb46258e96449e96fd577e52afd9c79b92c";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/svt-av1/libsvtav1enc1_1.4.1%2bdfsg-1_i386.deb";
        hash = "sha256:b00a3be28bc8200be35666e607f965a0e402091d154631128d07f01b0e376aa4";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/systemd/libsystemd0_252.39-1%7edeb12u1_i386.deb";
        hash = "sha256:5a6d339a54c53a6df58581e9281c9ef2c7b07fa2fc35c73dbb55de179bdfd00c";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/s/systemd/libudev1_252.39-1%7edeb12u1_i386.deb";
        hash = "sha256:da120590be3eca6a3230ac162ccde729fededce6644917b84c062528cf753eb8";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/t/taglib/libtag1v5_1.13-2_i386.deb";
        hash = "sha256:242f3cf94fb83434d2b5eecff57b85234f8535d52a0a0cfcc52c2e71dacb8169";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/t/taglib/libtag1v5-vanilla_1.13-2_i386.deb";
        hash = "sha256:fe94c557d82a27b2119a62d73aa05eeb27e9070ac7ab4cf06e37369b1939adea";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/t/twolame/libtwolame0_0.4.0-2_i386.deb";
        hash = "sha256:454e0fa798aca26d05937cbcccc3546196fd294919d417003646931b7dd0c293";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/u/unixodbc/libodbc2_2.3.11-2%2bdeb12u1_i386.deb";
        hash = "sha256:43de2e3c0cb42359a68930fae88ca03847643a5b78be4a8f7ca03fb7f68fd149";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/u/util-linux/libblkid1_2.38.1-5%2bdeb12u3_i386.deb";
        hash = "sha256:239ced602de059f88a86cde6af38fb0fc6a3193a3937c8e624c9d0c60831d430";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/u/util-linux/libmount1_2.38.1-5%2bdeb12u3_i386.deb";
        hash = "sha256:fea906e66b4b5c2f3cd6b3563f813e3cf7b3e007f21fd14101a99ab9f2451efb";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/v/v4l-utils/libv4l-0_1.22.1-5%2bb2_i386.deb";
        hash = "sha256:18c8395bf1d522dfece4cde0d36275ad9905c35dbf59b5d011268c7c32e167f7";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/v/v4l-utils/libv4lconvert0_1.22.1-5%2bb2_i386.deb";
        hash = "sha256:b6d70ee892cd2ec3a0d7266ad33547edd36ad4605a32ebe91e3508be5d6a770d";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/v/vulkan-loader/libvulkan1_1.3.239.0-1_i386.deb";
        hash = "sha256:a0b91b40d5e6cd29993a66f0a922d455cebdcf770f43ca14c60916c3bdc18284";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/w/wavpack/libwavpack1_5.6.0-1_i386.deb";
        hash = "sha256:e2cb06f8bf0babf9bc34781aa1c4f76b1d40100c93ab4ab02966ea36cba33759";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/w/wayland/libwayland-client0_1.21.0-1_i386.deb";
        hash = "sha256:1454b74db0b175bd4ef2b14ca6e66269e5d05e1bafa4fdaa6efa15424872061a";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/w/wayland/libwayland-cursor0_1.21.0-1_i386.deb";
        hash = "sha256:5ea0a94c004d546fc41e426a47269b4251af8a0e691db57a011d72f43c62d3b7";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/w/wayland/libwayland-egl1_1.21.0-1_i386.deb";
        hash = "sha256:0b73ffd5ddd6b3c6fbbd74dc0b5d8259614515e89e791fafe3472168f6b0149c";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/w/wayland/libwayland-server0_1.21.0-1_i386.deb";
        hash = "sha256:77a4e91792cfd2a48ee764659e28b301147af7968e7169c92477fab529f3ae13";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/w/wine/libwine_8.0%7erepack-4_i386.deb";
        hash = "sha256:c992aad6a47d81b719514f5d06c5df10267f1e40a6f4f3b4e3f655cbbf308d57";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/w/wine/wine32_8.0%7erepack-4_i386.deb";
        hash = "sha256:8d2ea88c4f45e813401e10f139456098f21a9a68440b36ea0da4644a2cbe21f8";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/x/x264/libx264-164_0.164.3095%2bgitbaee400-3_i386.deb";
        hash = "sha256:841509b7981f998ebb64f31ecb04be8e2dcdbf8ec3cd9918bda26e8a35f04eb0";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/x/x265/libx265-199_3.5-2%2bb1_i386.deb";
        hash = "sha256:9c4e46ac08327620715c63c33acb5cd54bf4a2496673928f46a865b38e5c939d";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/x/xvidcore/libxvidcore4_1.3.7-1_i386.deb";
        hash = "sha256:c91ac3ddfd171c4e2027d7c20dcc967ec761fb2678f1cf75cd94d7c59fcea754";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/x/xz-utils/liblzma5_5.4.1-1_i386.deb";
        hash = "sha256:beb15a6116bc404a0c3db7c978e08a32c988717d84b6c48db6ac16afbbb9ff92";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/z/z3/libz3-4_4.8.12-3.1_i386.deb";
        hash = "sha256:e8836fe68ad6165e22b215a18a07305a92ef30b86f4cc544052543033d0e3b0a";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/z/zlib/zlib1g_1.2.13.dfsg-1_i386.deb";
        hash = "sha256:3ca84a1245347652b7e1f8694db222851f7f1e7060515b21e1439b0cf84f96e1";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian/pool/main/z/zvbi/libzvbi0_0.2.41-1_i386.deb";
        hash = "sha256:7a7299d0319e628122f599e9e5b4554e10a76f3e375496917173f5e10d9bbcd9";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian-security/pool/updates/main/t/tiff/libtiff6_4.5.0-6%2bdeb12u3_amd64.deb";
        hash = "sha256:865574d933313e9900f67dd6db8410b491bb50e6bb66c32483388e219089d97a";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian-security/pool/updates/main/c/cups/libcups2_2.4.2-3%2bdeb12u9_i386.deb";
        hash = "sha256:593ef58636bd802b173c90be16e2ad20b4831a69cda31483aa64ee4c975d0826";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian-security/pool/updates/main/o/openssl/libssl3_3.0.17-1%7edeb12u3_i386.deb";
        hash = "sha256:2aacaa900ed6df88a4f5ef50646cabc9b7fd74bec8ea8a0d01f8980c25a9ca99";
      })
      (fetchurl {
        url = "http://deb.debian.org/debian-security/pool/updates/main/t/tiff/libtiff6_4.5.0-6%2bdeb12u3_i386.deb";
        hash = "sha256:66780a6fb7b614bbfcbdd7270d1d9b23b5e00165d80d4ff009be7eb1286efd12";
      })
    ];
    preInstall = "dpkg --add-architecture i386";
    layerHash = "sha256-q2+XIrjdjfcnoW/9Osm8M+h1I+epPloXfdbOfgI1gLM=";
    vmDiskSize = 4096;
    base = stamp.installDebianPkgs {
      pkgs = [
        # Top-level packages to install:
        #   wine (for moria)
        #   libatomic1 libpulse-dev (for valheim)
        #   dumb-init procps (utility)
        # Discover dependencies using: apt-get install -y --no-install-recommends ...
        # Generate URLs and hashes using: apt-get download --print-uris PACKAGE...
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/a/abseil/libabsl20220623_20220623.1-1%2bdeb12u2_amd64.deb";
          hash = "sha256:3fb1a98ff3a1b7b27cd3b2544e033af3bc3419d82f33bbe3f3d5faa07b400eb5";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/a/alsa-lib/libasound2_1.2.8-1%2bb1_amd64.deb";
          hash = "sha256:44c77b076a7b11ae99712439022d822245b1994c435da564ebd320bb676faf4c";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/a/alsa-lib/libasound2-data_1.2.8-1_all.deb";
          hash = "sha256:fe0780d2d3674b2977e0acb0d48b448ad72ba1642564b7dc537f55e839984c2d";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/a/aom/libaom3_3.6.0-1%2bdeb12u2_amd64.deb";
          hash = "sha256:33fd9b3af7c1bf65fd7e603d60f5034ac3bc0b4eefdabd8c33de8daff0e87205";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/d/dav1d/libdav1d6_1.0.0-2%2bdeb12u1_amd64.deb";
          hash = "sha256:197f08108242177aeae4c04aac11825c39b7d18598191ab769f910687ccb387f";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/d/dbus/libdbus-1-3_1.14.10-1%7edeb12u1_amd64.deb";
          hash = "sha256:18ee0ce5fab9f7b671e87da1e9fa18660e36e04a3402f24bdb8635e0ba1d35f6";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/d/dumb-init/dumb-init_1.2.5-2_amd64.deb";
          hash = "sha256:a8eae71eb01d0b1c378708a8dbef0247615e9f9d43dd7b37ca77958963360afd";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/e/elfutils/libdw1_0.188-2.1_amd64.deb";
          hash = "sha256:ffd7b1bad982ad1afd9c2b75ab2edd18e229508df731a8f4d8443f093a91442f";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/e/elfutils/libelf1_0.188-2.1_amd64.deb";
          hash = "sha256:619add379c606b3ac6c1a175853b918e6939598a83d8ebadf3bdfd50d10b3c8c";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/e/expat/libexpat1_2.5.0-1%2bdeb12u2_amd64.deb";
          hash = "sha256:2255e62fc22a86d2c544b8a3f516da9aee19383ad5742722ab4ce7f66a30dbc8";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/f/flac/libflac12_1.4.2%2bds-2_amd64.deb";
          hash = "sha256:4d8431c274eef13ec9ee2c0bf988c34b4342367dec053b7f69a432525be5b1fe";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/f/fontconfig/fontconfig-config_2.14.1-4_amd64.deb";
          hash = "sha256:281c66e46b95f045a0282a6c7a03b33de0e9a08d016897a759aaf4a04adfddbe";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/f/fontconfig/libfontconfig1_2.14.1-4_amd64.deb";
          hash = "sha256:16ee38d374e064f534116dc442b086ef26f9831f1c0af7e5fb4fe4512e700649";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/f/fonts-dejavu/fonts-dejavu-core_2.37-6_all.deb";
          hash = "sha256:8892669e51aab4dc56682c8e39d8ddb7d70fad83c369344e1e240bf3ca22bb76";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/f/freetype/libfreetype6_2.12.1%2bdfsg-5%2bdeb12u4_amd64.deb";
          hash = "sha256:8043e479f73f29992d652e3f9dfe8b17f9780c7ea6330afe379ec5f9f188ac44";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/g/gcc-12/libatomic1_12.2.0-14%2bdeb12u1_amd64.deb";
          hash = "sha256:fbd4e154a6b444229ea002cc209df099209c0adc09102e5fd21239a3d2b55e2d";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/g/glib2.0/libglib2.0-0_2.74.6-2%2bdeb12u7_amd64.deb";
          hash = "sha256:715d4dbc3e324534b5317e2ed2c78f69aa45b6b7b720dc76e7fa8ff2621bff81";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/g/glib2.0/libglib2.0-bin_2.74.6-2%2bdeb12u7_amd64.deb";
          hash = "sha256:11e49ee588b4d9753d2b0d52ffadaa01bc2f08d4f2219c7ef3d5598ebf316489";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/g/glib2.0/libglib2.0-data_2.74.6-2%2bdeb12u7_all.deb";
          hash = "sha256:15f9df98b5eda9b03fb0c9d67a54b63740126771defd8038245dca29b2a3584f";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/g/glib2.0/libglib2.0-dev_2.74.6-2%2bdeb12u7_amd64.deb";
          hash = "sha256:e5a676cde298cc0ebcb8d3a012b50784eb81e10123fc02e794471bd70d5439b7";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/g/glib2.0/libglib2.0-dev-bin_2.74.6-2%2bdeb12u7_amd64.deb";
          hash = "sha256:abc8fe1b4bc4d4aa1a02034c55d87d66266b318678f1c8d6464443a40d2b4a06";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/g/glibc/libc-dev-bin_2.36-9%2bdeb12u13_amd64.deb";
          hash = "sha256:7eff38f793edc47d006b65ca902eac63e5ab9f6d41b027e358870d9795207c9f";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/g/glibc/libc6-dev_2.36-9%2bdeb12u13_amd64.deb";
          hash = "sha256:1c07eaab8aeb1c8d18c14ff16e2e5ccc8135d51e0d8926cc1c50db5b98e4aa33";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/g/gst-plugins-base1.0/libgstreamer-plugins-base1.0-0_1.22.0-3%2bdeb12u5_amd64.deb";
          hash = "sha256:5a184ae767f84f1cca716f8b5c374c4861f2301537f9c36a1061c33edd121443";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/g/gstreamer1.0/libgstreamer1.0-0_1.22.0-2%2bdeb12u1_amd64.deb";
          hash = "sha256:97fa34146e892871db0b60b70494b238519c5ae906ddbdd31c39a5a77b5e5499";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/i/icu/libicu72_72.1-3%2bdeb12u1_amd64.deb";
          hash = "sha256:f7f6f99c6d7b025914df2447fc93e11d22c44c0c8bdd8b6f36691c9e7ddcef88";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/i/iso-codes/iso-codes_4.15.0-1_all.deb";
          hash = "sha256:b1beb869303229c38288d4ddacfd582c91f594759b5767c9cecebd87f16ff70e";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/j/jbigkit/libjbig0_2.1-6.1_amd64.deb";
          hash = "sha256:6b07c77b700a615642888a82ba92a7e7c429d04b9c8669c62b2263f15c4c4059";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/l/lame/libmp3lame0_3.100-6_amd64.deb";
          hash = "sha256:b1292c749172e7623547ecf684da57d3ec6ca22109f08b11bbb9e6be6e6beb95";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/l/lerc/liblerc4_4.0.0%2bds-2_amd64.deb";
          hash = "sha256:771f5c47ca69f24ca61e4be0c98c5912b182ce442f921697d17a472f3ded5c9c";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/liba/libasyncns/libasyncns0_0.8-6%2bb3_amd64.deb";
          hash = "sha256:cadaff99f4178b1f580331045621b363abaaefc994e78eecba1857774a3cead2";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/liba/libavif/libavif15_0.11.1-1%2bdeb12u1_amd64.deb";
          hash = "sha256:c79d57f0f62d67d2353765592fb4f519119392befa53d27a34c9d0348cd580a3";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libb/libbsd/libbsd0_0.11.7-2_amd64.deb";
          hash = "sha256:bb31cc8b40f962a85b2cec970f7f79cc704a1ae4bad24257a822055404b2c60b";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libc/libcap2/libcap2-bin_2.66-4%2bdeb12u2_amd64.deb";
          hash = "sha256:65eb89c74f863dc365088dcd061cf603d73e121b1d17fab2945bb3f292774fd0";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libc/libcapi20-3/libcapi20-3_3.27-3%2bb1_amd64.deb";
          hash = "sha256:c2b9518d5457e4495a85334ff4b5d5abd8d15ef2b80a153aa2f95a920d4aeff1";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libd/libde265/libde265-0_1.0.11-1%2bdeb12u2_amd64.deb";
          hash = "sha256:cef2a550eb3aa0f7d01799a3ab5d5c10b48d0184c41d23ebdefd2e43f0800f42";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libd/libdeflate/libdeflate0_1.14-1_amd64.deb";
          hash = "sha256:3d4b39f94317b64a860db8a7a8b581b555124cd461fe07ec0d347edbdb9f6683";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libe/libexif/libexif12_0.6.24-1%2bb1_amd64.deb";
          hash = "sha256:fa26e3230b3f3c875538fbf282db02888e5bc971d83b95012c958674f06626f8";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libf/libffi/libffi-dev_3.4.4-1_amd64.deb";
          hash = "sha256:89fb890aee5148f4d308a46cd8980a54fd44135f068f05b38a6ad06800bf6df3";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libg/libgav1/libgav1-1_0.18.0-1%2bb1_amd64.deb";
          hash = "sha256:4cf64c4e1168f3c7e858bb4a71f2c5bea9a36dd448cdcc2154a551ac146e293b";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libg/libgd2/libgd3_2.3.3-9_amd64.deb";
          hash = "sha256:d3564267cef9f0162ad21b73d34b6a4302ee3a84426188168d74be737b079647";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libg/libgphoto2/libgphoto2-6_2.5.30-1_amd64.deb";
          hash = "sha256:63db08e7970759446d16420ad2d89041fef383dd290e63bdcb4629276c6b33b7";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libg/libgphoto2/libgphoto2-port12_2.5.30-1_amd64.deb";
          hash = "sha256:82e017750aa6db74d8b4456c449d8353d6a56791aee50c032827f5ffc7c3a4b2";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libh/libheif/libheif1_1.15.1-1%2bdeb12u1_amd64.deb";
          hash = "sha256:13a0a3a6e22ddf5eb891b7c7873ace79f13f2c96473576e5f7da2ae3228a2113";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libj/libjpeg-turbo/libjpeg62-turbo_2.1.5-2_amd64.deb";
          hash = "sha256:95ec30140789a342add8f8371ed018924de51b539056522b66f207b25cba9cad";
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
          url = "http://deb.debian.org/debian/pool/main/libp/libpcap/libpcap0.8_1.10.3-1_amd64.deb";
          hash = "sha256:856014904c4d7ec9a9ba864c546d91c059b9bf00c7c89eda6fd0a16045f8faac";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libp/libpng1.6/libpng16-16_1.6.39-2_amd64.deb";
          hash = "sha256:dc32727dca9a87ba317da7989572011669f568d10159b9d8675ed7aedd26d686";
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
          url = "http://deb.debian.org/debian/pool/main/libs/libsndfile/libsndfile1_1.2.0-1%2bdeb12u1_amd64.deb";
          hash = "sha256:02dc3f08fe8476e82e005f412e3b7289ff641180f33a9be8073f4bde61c85e8e";
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
          url = "http://deb.debian.org/debian/pool/main/libt/libtool/libltdl7_2.4.7-7%7edeb12u1_amd64.deb";
          hash = "sha256:8070b550321d4bd1c298f52f75374898d39112b709026d2ea5362ef1277b775a";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libu/libunwind/libunwind8_1.6.2-3_amd64.deb";
          hash = "sha256:7b297868682836e4c87be349f17e4a56bc287586e3576503e84a5cb5485ce925";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libu/libusb-1.0/libusb-1.0-0_1.0.26-1_amd64.deb";
          hash = "sha256:0a8a6c4a7d944538f2820cbde2a313f2fe6f94c21ffece9e6f372fc2ab8072e1";
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
          url = "http://deb.debian.org/debian/pool/main/libw/libwebp/libwebp7_1.2.4-0.2%2bdeb12u1_amd64.deb";
          hash = "sha256:7259b7ce46444694ce536360ad53acb68eb3b47a7ff81d7b1b8a3939b2ac9918";
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
          url = "http://deb.debian.org/debian/pool/main/libx/libxext/libxext6_1.3.4-1%2bb1_amd64.deb";
          hash = "sha256:504b7be9d7df4f6f4519e8dd4d6f9d03a9fb911a78530fa23a692fba3058cba6";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libx/libxml2/libxml2_2.9.14%2bdfsg-1.3%7edeb12u4_amd64.deb";
          hash = "sha256:f3bac32a5f7d32990af06713eef57664a66e98c13750fa8e007c9cbaf49b98c7";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libx/libxpm/libxpm4_3.5.12-1.1%2bdeb12u1_amd64.deb";
          hash = "sha256:505400598dcda712380f2e4a73b09b015a3fedf78bd874f6429622c448e249f9";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/liby/libyuv/libyuv0_0.0%7egit20230123.b2528b0-1_amd64.deb";
          hash = "sha256:48225793c486310600459d08a417dca0c28cbaf184047c09c82aff19107aa6f2";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/libz/libz-mingw-w64/libz-mingw-w64_1.2.13%2bdfsg-1_all.deb";
          hash = "sha256:b9e73ca486bc2aa66da86b5724220d2dd7c8299636b1df74c3414757a2170615";
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
          url = "http://deb.debian.org/debian/pool/main/n/numactl/libnuma1_2.0.16-1_amd64.deb";
          hash = "sha256:639e1ab6bd66ead40db8a22c332d7199679fa22db261cac34444eb8eb4c17dda";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/o/ocl-icd/ocl-icd-libopencl1_2.3.1-1_amd64.deb";
          hash = "sha256:ddd8509c0430545173752bed272c7f44f8b5f7d125265b20456207aaefbb52c8";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/o/opus/libopus0_1.3.1-3_amd64.deb";
          hash = "sha256:c172e212f9039e741916aa8e12f3670d1e049dc0c16685325641288c2d83faa7";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/o/orc/liborc-0.4-0_0.4.33-2_amd64.deb";
          hash = "sha256:f2b775c4281fc4d02432833cef274cfaa927a446bdf619f02292bd83b201fe3a";
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
          url = "http://deb.debian.org/debian/pool/main/r/rust-rav1e/librav1e0_0.5.1-6_amd64.deb";
          hash = "sha256:c266adb3545b0b8ff6450dbd09f85f19361bf5bc9290ddf2e869f040cb9725b7";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/s/sqlite3/libsqlite3-0_3.40.1-2%2bdeb12u2_amd64.deb";
          hash = "sha256:a8d78b40e9b4e422224aeebfe0e4dfc243f6acf3532490b0c05480d4283d41e2";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/s/svt-av1/libsvtav1enc1_1.4.1%2bdfsg-1_amd64.deb";
          hash = "sha256:e0f6e357f327e80f26438dcda9c9304c43e2f3343359c6a5075d0b10ddfdb05d";
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
          url = "http://deb.debian.org/debian/pool/main/w/wine/libwine_8.0%7erepack-4_amd64.deb";
          hash = "sha256:512b715f32fccf2ebec2b63f23d9d83394d30e27cc5570a8ef92c5d3627ef305";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/w/wine/wine_8.0%7erepack-4_all.deb";
          hash = "sha256:79672e2f542c450fe7e7a16a930ac8787fcfa804d29c2bf37e3d33297dbe60b0";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/w/wine/wine64_8.0%7erepack-4_amd64.deb";
          hash = "sha256:4ff56d97fb84c41dd450775f03ae42208f092e822f9baa742dcde951773ecb42";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/x/x265/libx265-199_3.5-2%2bb1_amd64.deb";
          hash = "sha256:9cd87d1b0c56f34f51bcbe8bdb55ebb45dd08ce6c0c6ff2dc77378bac3f64cc0";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian/pool/main/z/zlib/zlib1g-dev_1.2.13.dfsg-1_amd64.deb";
          hash = "sha256:f9ce531f60cbd5df37996af9370e0171be96902a17ec2bdbd8d62038c354094f";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian-security/pool/updates/main/l/linux/linux-libc-dev_6.1.158-1_amd64.deb";
          hash = "sha256:c283737cb5d2ed7da558528b3b69d25dc2f995cfe42f35883354e9b1a7c7dc24";
        })
        (fetchurl {
          url = "http://deb.debian.org/debian-security/pool/updates/main/t/tiff/libtiff6_4.5.0-6%2bdeb12u3_amd64.deb";
          hash = "sha256:865574d933313e9900f67dd6db8410b491bb50e6bb66c32483388e219089d97a";
        })
      ];
      layerHash = "sha256-07gEsKEs0+9vQkoLQOV2UMVcefi0xqwiAkMjx3xQsYs=";
      base = stamp.fetch {
        repository = "docker.io/cm2network/steamcmd";
        digest = "sha256:87ae768b11d72d0c3bd708311527758f8b0cc711ac1b21f5654b1c720652751c"; # 'latest' tag
        hash = "sha256-YujF1svbRBIT8foCWPNsHUUlWa83ozHnyrLKXgK2rW4=";
      };
    };
  };
}
