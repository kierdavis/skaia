{ fetchurl, fakeHash }:

{
  alsa-lib = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/alsa-lib-1.2.10-r0.apk";
    hash = "sha256:0mvi4bgldprzwdmp2vbf9j916xg7n1cynjab6ic8y14ha4yamx95";
  };
  aom-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/aom-libs-3.7.1-r0.apk";
    hash = "sha256:1n520xbla1z4xqryjlpjzafqyw35k7i3p6c1bkf7ms5nqyyg5s5c";
  };
  brotli-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/brotli-libs-1.1.0-r1.apk";
    hash = "sha256:05p5ffhflpw7wcbwlchsxqqlb1313hxp4mfnayncmbwayb9k1d9m";
  };
  ca-certificates = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/ca-certificates-20241121-r1.apk";
    hash = "sha256:1zgc6ld23d63wwvv4ndlbalnl8m43fsaaf62pz96kzlx7xf8xn5y";
  };
  c-ares = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/c-ares-1.27.0-r0.apk";
    hash = "sha256:16ilchcnp1qmzc6clcd8nixdss6p9zs7g54ww050n9mi8x1gzbfp";
  };
  cjson = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/cjson-1.7.17-r0.apk";
    hash = "sha256:088wiggiaa7wjfn2gc6jrmbq6rvxv1nczlz87k7addcb716vg8si";
  };
  curl = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/curl-8.12.1-r0.apk";
    hash = "sha256:09yg29i7bp087rmqz5iqkwkw3091rab6j4j08212bzf57n03w5xn";
  };
  dbus-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/dbus-libs-1.14.10-r0.apk";
    hash = "sha256:15lzfvrv50728dlw4wz4d04x5yznma7f2sxgpskylafkzxlscxqr";
  };
  dumb-init = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/dumb-init-1.2.5-r3.apk";
    hash = "sha256:0mjsbna4c9m7bslynw9gx225n8by5driv9jkhg43v4m2mm82y4km";
  };
  ffmpeg = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/ffmpeg-6.1.1-r0.apk";
    hash = "sha256:1737gzzwip0ywmj5wfs9llxhl36wwfd4l20dbwzb3dzjvgk0ll7w";
  };
  ffmpeg-libavcodec = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/ffmpeg-libavcodec-6.1.1-r0.apk";
    hash = "sha256:0svwmivaba0hxcpw780qyjwg80j9g26a2f99psscwx0zzsibbs2j";
  };
  ffmpeg-libavdevice = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/ffmpeg-libavdevice-6.1.1-r0.apk";
    hash = "sha256:06bxm6hw006fdfmp4bpz84707nc38892xahnp0bsg1f5rvnj4nxb";
  };
  ffmpeg-libavfilter = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/ffmpeg-libavfilter-6.1.1-r0.apk";
    hash = "sha256:0pi7z1dhy0ysanfg0k1canivbacdbk8b3ah2d24pgmslpjgnkdkn";
  };
  ffmpeg-libavformat = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/ffmpeg-libavformat-6.1.1-r0.apk";
    hash = "sha256:0jrpkakc11ambria9l0lfbynkvm100dl22jk4iwn0l38n8pin1na";
  };
  ffmpeg-libavutil = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/ffmpeg-libavutil-6.1.1-r0.apk";
    hash = "sha256:1nqqpbgig72fqpw89x2s1hd5vv428nrii7zcjxshg2a2gip2wkc2";
  };
  ffmpeg-libpostproc = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/ffmpeg-libpostproc-6.1.1-r0.apk";
    hash = "sha256:1g8fsi9j8in9crana2b0jjiqlmf3szla96wzadq0vxx94mb2wjmb";
  };
  ffmpeg-libswresample = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/ffmpeg-libswresample-6.1.1-r0.apk";
    hash = "sha256:0a3anv1lravfvxjk3pd0b020ad04li12x39k1syr77z64c1s95vp";
  };
  ffmpeg-libswscale = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/ffmpeg-libswscale-6.1.1-r0.apk";
    hash = "sha256:08cmrhqla4jmfjix3b10f4f2w8r16kp9nis8cdaw41rw19rd163y";
  };
  fontconfig = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/fontconfig-2.14.2-r4.apk";
    hash = "sha256:16ycprl3c7lqsw4ixz3m6dj9j2p11jk0niwqnv98d0x3y3k6m209";
  };
  freetype = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/freetype-2.13.2-r0.apk";
    hash = "sha256:06cf11535gfzh98wgwaf2n383g24nq6hrvgvx21wbpig0r9ny639";
  };
  fribidi = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/fribidi-1.0.13-r0.apk";
    hash = "sha256:102ny52pl2s4bhnhpanjs69wzd3m3f1f8qyx5936kwjqw37jv35q";
  };
  gdbm = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/gdbm-1.23-r1.apk";
    hash = "sha256:1h5grsvcb5qshg9f0z5izz2qgy2hjdka5hfb9mmc25pdnl4cjfkq";
  };
  giflib = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/giflib-5.2.2-r0.apk";
    hash = "sha256:073d6kgaph9j9c1r9zpzp5v4rqhmxa1z7z9yardag8rc008g9kvz";
  };
  glib = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/glib-2.78.6-r0.apk";
    hash = "sha256:16c8yz8c6nss8ncas33q2fnidhyzclp8lykpwhi1f9fqhcy2jn82";
  };
  glslang-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/glslang-libs-1.3.261.1-r0.apk";
    hash = "sha256:1y4672w0nx8dzd10qp3l55wzzr9mfiknladl12l4kdb9713h1zfa";
  };
  graphite2 = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/graphite2-1.3.14-r6.apk";
    hash = "sha256:0c4vjr4x0vn2cixacjl4nj8ic1dbxsik135mjdy70df7pjglyaxy";
  };
  harfbuzz = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/harfbuzz-8.3.0-r0.apk";
    hash = "sha256:064yc1jvij3d5h65g5h1acn5nr1r0431qd9ikc2i4krwm19hvyrk";
  };
  hwdata-pci = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/hwdata-pci-0.377.2-r0.apk";
    hash = "sha256:06j9pxklvwxj1mvnh6q695110dcha5ad2gpdcp5gfwbmflms2qcd";
  };
  imath = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/imath-3.1.9-r3.apk";
    hash = "sha256:1xala9dz7ga0vrc0gbcdkv0v85my24mqyz4hm3g9acx7bbqxcqz7";
  };
  intel-gmmlib = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/intel-gmmlib-22.3.12-r0.apk";
    hash = "sha256:0yz874s9p6h39kip2sqpy4hwgq3fl5h0642vivsbxspxag2bc9ii";
  };
  intel-media-driver = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/intel-media-driver-23.3.5-r0.apk";
    hash = "sha256:0w99vj4g49rydjmzkhcnqncjz79qbf4yv5yygv7gwzvlnp3ab44f";
  };
  iproute2-minimal = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/iproute2-minimal-6.6.0-r0.apk";
    hash = "sha256:12d916b4s58jg4awv9izhcg7r3rhlarraxkfba546pakfhw2aw1v";
  };
  lame-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/lame-libs-3.100-r5.apk";
    hash = "sha256:1q8i9rrhqddkdcalpk09xpb964w8ybv3xqipkwxmvfvgvl2l7752";
  };
  lcms2 = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/lcms2-2.15-r4.apk";
    hash = "sha256:0z35dhvla3axirqygdi2mgjp1in89yc5yhrxjk5yv7psbz333z83";
  };
  libass = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libass-0.17.1-r1.apk";
    hash = "sha256:1s295hws4bv98v327c3f4bhzzcci7m4izxpsxg37ka02qpwg4w6v";
  };
  libasyncns = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libasyncns-0.8-r2.apk";
    hash = "sha256:02ndr0mfr6iyckbc5yp3g4pf992balnwhpxzalvbgil6xgqbscid";
  };
  libblkid = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libblkid-2.39.3-r0.apk";
    hash = "sha256:06h5fgy5mlc4c27r9xscwx65fb8rf67ch90jxygg3nhgmf0zhb16";
  };
  libbluray = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libbluray-1.3.4-r1.apk";
    hash = "sha256:1mfc88kcf02b2i2cllm0xb4xd51b91z2l6j006j95szsbcnc6cbi";
  };
  libbsd = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libbsd-0.11.7-r3.apk";
    hash = "sha256:1jyh26ibq7q61s5frf0qv3imb38f36lkxdffpdq142vad2709gak";
  };
  libbz2 = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libbz2-1.0.8-r6.apk";
    hash = "sha256:0sh0f9cqsra7kraxz6i7y2v33phf4bgz5kwnni6np4gabfix1x57";
  };
  libcap-ng = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libcap-ng-0.8.3-r4.apk";
    hash = "sha256:03zvi2mwda13lv92pd8j8gmj65ywrr2ry0qinjnks42r26wi7zbh";
  };
  libcap2 = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libcap2-2.69-r1.apk";
    hash = "sha256:0dgmk8bfccq699x2dgqv65cna85q7vd64qyawi25df72zrvkfwz5";
  };
  libcurl = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libcurl-8.12.1-r0.apk";
    hash = "sha256:1nba8f5vmzqd6pj7bi4rld31dk79m2xlzb9hy9rl7r4ppjsf5nx8";
  };
  libdav1d = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libdav1d-1.3.0-r1.apk";
    hash = "sha256:0c8ilqg8l4q9fb02jczzli1xvcbj6asw1ii2lflmsqj3jg8qrs21";
  };
  libdeflate = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libdeflate-1.19-r0.apk";
    hash = "sha256:0w8q6klq0vmg16r7ll6p6z7rcbax76g4dwjc2x442dxakz65gvwp";
  };
  libdovi = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libdovi-3.2.0-r1.apk";
    hash = "sha256:0n6dmbrkj08kz69cscj5cxyvzv0vrnw3ljnihxr20fk8dj05443l";
  };
  libdrm = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libdrm-2.4.118-r0.apk";
    hash = "sha256:01q0bh90vgcgy02xflj9pj4a5p7agx4hchkcfmcz21vcp59bfhhj";
  };
  libeconf = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libeconf-0.5.2-r2.apk";
    hash = "sha256:1i84f6s2fxzc8xgi9qpcq20m63hv1kq25gjin24h8ij3zvacacf2";
  };
  libelf = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libelf-0.190-r1.apk";
    hash = "sha256:1rvbdq7wxih66s56cl2fk79lijr4rjd9yn621gagj47hj8ynd808";
  };
  libexpat = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libexpat-2.7.0-r0.apk";
    hash = "sha256:0irli09mwjkb2n59fylg80qxm9f9avyg6dnmn9q6y4vs1zvrw5yc";
  };
  libffi = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libffi-3.4.4-r3.apk";
    hash = "sha256:0igrci6pnbl8hgkc9mj030n2886yrmnnik2fnnnl9ml6jc2p8cpq";
  };
  libflac = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libflac-1.4.3-r1.apk";
    hash = "sha256:0wdd44rahywy1fnc21shxqdxx0czjyx2wgwmnnzy82i6qybm4hqy";
  };
  libgcc = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libgcc-13.2.1_git20231014-r0.apk";
    hash = "sha256:0am4z4qrl73n4pjmndrqrmq786xrjshynah5n08700linwlp0npn";
  };
  libgomp = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libgomp-13.2.1_git20231014-r0.apk";
    hash = "sha256:1avfl5z6xs7fkgwr6w4cj975y56l072rp6p6rbq122csfw59z6y8";
  };
  libhwy = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libhwy-1.0.7-r0.apk";
    hash = "sha256:1mq926ncm5idhjl0k94b0xhy7g9cpi6sf957n1zcbs5r89kwfh8h";
  };
  libidn2 = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libidn2-2.3.4-r4.apk";
    hash = "sha256:0xxl2j6vnfj1nxj7b13xmf8g2n6xkr0yhfshm03vnskpjq6yd4kl";
  };
  libintl = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libintl-0.22.3-r0.apk";
    hash = "sha256:0d4qhc0xk09lbxdb2ksw2iz1q9j9qfqa6har6bmfi59ww3yx3m98";
  };
  libjpeg-turbo = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libjpeg-turbo-3.0.1-r0.apk";
    hash = "sha256:0riy0iyprhlrf95p4csg847smykf4g4nifnyr914mh9rvlczbfgk";
  };
  libjxl = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libjxl-0.8.2-r0.apk";
    hash = "sha256:1rhcnvbm87gbjv37npjn8k6bvilm934fqz8qfkfvwpjg07kk73g7";
  };
  libltdl = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libltdl-2.4.7-r3.apk";
    hash = "sha256:0g31a47jd6my9hcqnimdz7vrzlvpmksw77mqdrvqmdqsmdnaci6w";
  };
  libmd = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libmd-1.1.0-r0.apk";
    hash = "sha256:18iny8dz0ylgnd9w5paw0hw5lpmpkgsqbkxcazc74wqf6hadmvji";
  };
  libmnl = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libmnl-1.0.5-r2.apk";
    hash = "sha256:1d6y4b719bfyf74yqipsp2cj1jzwwkgc7dlh9vlxqcaq421yhb1j";
  };
  libmount = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libmount-2.39.3-r0.apk";
    hash = "sha256:17h8ka3fy2v2qw9q9ij2mfxikrv1j96as62xfma3yijc91mavzlh";
  };
  libncursesw = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libncursesw-6.4_p20231125-r0.apk";
    hash = "sha256:1q7hvfpaq7j1b6fk6c9yc20m3a85dggvrhq1ivjhnj5lsmq0z0wl";
  };
  libogg = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libogg-1.3.5-r5.apk";
    hash = "sha256:0x9jlx25yf6rhxq6ndiivm3bhww4q74lnc28990dcha9a4yzdp90";
  };
  libopenmpt = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libopenmpt-0.7.3-r1.apk";
    hash = "sha256:01p0015bl7wdbhfy0cqfj0lp0l5n3ki0m0szfcv4lrgghkk04wc7";
  };
  libpanelw = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libpanelw-6.4_p20231125-r0.apk";
    hash = "sha256:1fg5gzc9ks9ychqfhb0h138zdgwdpily91bcx5w4dinr61z9n9yl";
  };
  libpciaccess = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libpciaccess-0.17-r2.apk";
    hash = "sha256:0bczggk56r0hcwrkjmgw0g7a3c9jp4ahaz33bw2mwqxdavh0a8qq";
  };
  libplacebo = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libplacebo-6.338.1-r0.apk";
    hash = "sha256:0gfsykljrnfnnr7l4bh2pssy5m6813fj3p0jp54qsbblap0png5q";
  };
  libpng = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libpng-1.6.44-r0.apk";
    hash = "sha256:1xgc41r1zwjl00whh10qa44n5xkxshkmp97q4lawi5r38cx1vqnm";
  };
  libpsl = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libpsl-0.21.5-r0.apk";
    hash = "sha256:1iys67pwmxikn9cf1nsndfa9d2p388yahl4518ihp7sn6881qn4w";
  };
  libpulse = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libpulse-16.1-r11.apk";
    hash = "sha256:1xkb8dl41vablwlzmafvys4asrn20lc4chjh9qn4x2g5v1n44vrj";
  };
  librist = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/librist-0.2.10-r0.apk";
    hash = "sha256:0k044k8j0cyvq33nvmhcvpkf6qfzkz631jc4kxz5b7qrw2n8wnc9";
  };
  libsharpyuv = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libsharpyuv-1.3.2-r0.apk";
    hash = "sha256:0w0dby7bmfzafpblr2d835991nnrlia1b8ray3dbpgl4vx0ikpxh";
  };
  libsndfile = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libsndfile-1.2.2-r1.apk";
    hash = "sha256:0kwc4cjnj3gjp3ry0ivfsiijhwxz824dq67fsxkh7habn90pl3n4";
  };
  libsodium = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libsodium-1.0.19-r0.apk";
    hash = "sha256:10xmqb8rfkg1f3dg2gnf9bdnyxm9kkyvs09sv70xh0n22hkbkrvc";
  };
  libsrt = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libsrt-1.5.3-r0.apk";
    hash = "sha256:0zds0sxl0wvir34d76wr2c52z00jac48sa0dmmj332g8gg66m9qq";
  };
  libssh = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libssh-0.10.6-r0.apk";
    hash = "sha256:0f10h77v1j7wmlj8ks103cyvdj66f3158lsfmxmhmdzr8dsis0b5";
  };
  libstdcxx = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libstdc++-13.2.1_git20231014-r0.apk";
    hash = "sha256:09yh7b2iicy3q2c23kx9rd3aqss8bz3x75k4228ga3i4ciqnmxiw";
  };
  libSvtAv1Enc = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libSvtAv1Enc-1.7.0-r0.apk";
    hash = "sha256:0821zv6pd20gh6y0ny98jhidbxvh53nwgmnfwkp4iw8p0mixbhri";
  };
  libtheora = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libtheora-1.1.1-r18.apk";
    hash = "sha256:148a92pnp2wsqmshrkbbhsyr8k2ryhsd9w4drhzbmygdhh10w085";
  };
  libunibreak = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libunibreak-5.1-r3.apk";
    hash = "sha256:1v643ca1y1lfzmngndky1c0555xn7v24fhzf9gw8ndf88n6z6lfz";
  };
  libunistring = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libunistring-1.1-r2.apk";
    hash = "sha256:02zki3wav4h2sl7svamg6n2vc3il0ss0vj327ax9cdg0s806z0q8";
  };
  libva = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libva-2.20.0-r0.apk";
    hash = "sha256:0rgbnkwm9rxrwsp3ijfg2rj8a6zmmy31f0ixk62i30a1hw95375z";
  };
  libva-utils = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libva-utils-2.20.0-r0.apk";
    hash = "sha256:1plp8kw8xnqbh2s39kja0x4z0ys7x3mxa95ldm3z812n0dag9amx";
  };
  libvdpau = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libvdpau-1.5-r2.apk";
    hash = "sha256:1zja2p2kf7xbs3vg0cwcslkpq75dsynqbjj9xp2h7jar2hjlan7a";
  };
  libvorbis = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libvorbis-1.3.7-r2.apk";
    hash = "sha256:0plvr6whmgr7s9gznnpqidh7q2ip4klq8r2bazwyp924kaw3cvcw";
  };
  libvpx = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/libvpx-1.13.1-r0.apk";
    hash = "sha256:108l1bglv11rfys0mxxs5p8j2mm4nb0axyv0a5yq0kq8nk6a5yym";
  };
  libwebp = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libwebp-1.3.2-r0.apk";
    hash = "sha256:073ddrkz2ij0z5q7yb97ck9sjg2vbgm478nxnyhn9b638wcfjd67";
  };
  libwebpmux = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libwebpmux-1.3.2-r0.apk";
    hash = "sha256:09cp25r1c8lh6gc55ni5mzpz1d46kcrxzwm17bj1n1yxsmnljrrb";
  };
  libx11 = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libx11-1.8.7-r0.apk";
    hash = "sha256:0bmhra323rb2yqs2hnrzs16vdnwc4rcn93aqcly5cv214q1v7xh2";
  };
  libxau = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libxau-1.0.11-r3.apk";
    hash = "sha256:0k3bhlp3izlryq0j7rd6zbdiv9rycb85g2d8ri181dnfbd0i7saw";
  };
  libxcb = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libxcb-1.16-r0.apk";
    hash = "sha256:1dvkpb5y97sgpsm0h55980vxa4szbd3kqq8gbpc098n6v12pmnym";
  };
  libxdmcp = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libxdmcp-1.1.4-r3.apk";
    hash = "sha256:0ygz0df29ms7r91i76nzah9fyf42zl3p5px56rvmp68gr725jwn0";
  };
  libxext = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libxext-1.3.5-r3.apk";
    hash = "sha256:17qqkv4lxf7p303yqsnw3pfacc3y97acxhh0zfjsmfq0ivsrv6wp";
  };
  libxfixes = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libxfixes-6.0.1-r3.apk";
    hash = "sha256:046c0rd1r2nbzazq4xk5ja70wrrycxmvp6h076gq3qsgsjc9mz7l";
  };
  libxml2 = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libxml2-2.11.8-r2.apk";
    hash = "sha256:0vcf0gzwcl60xrmi3gh6nc02rxgwbaqw84m8w67fy6gpd4jfsq49";
  };
  libzmq = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/libzmq-4.3.5-r2.apk";
    hash = "sha256:02sn4hvb4mnmkf9125vc5i9c59d07fa9fpmd4lncwir3kjsr9di5";
  };
  lilv-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/lilv-libs-0.24.22-r0.apk";
    hash = "sha256:1iak08894qcj9afs9bg1ljr7c1iinp89az2yr48mp801fvjv16k1";
  };
  lz4-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/lz4-libs-1.9.4-r5.apk";
    hash = "sha256:11iqqdnj2rznzm3lv9bbb8av4pd9asl17v38ax2s1gr9wc0grd9s";
  };
  lzo = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/lzo-2.10-r5.apk";
    hash = "sha256:1zpd2h92xsa8aizwf73n8yrhmz9kflg8wpsqifl2b7z691i3bl88";
  };
  mbedtls = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/mbedtls-2.28.9-r0.apk";
    hash = "sha256:1z0r7k915zslmmnxzw49wgb60311kc8prhqs9mai3sdjw75hym96";
  };
  mpdecimal = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/mpdecimal-2.5.1-r2.apk";
    hash = "sha256:03vkanhq9wcq1ws3hafhpa2dwg5afnxhkvn974l5igrqc18vb268";
  };
  mpg123-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/mpg123-libs-1.32.8-r0.apk";
    hash = "sha256:0ia6rbyzrild8hrlfhcn3jm49q9hcfa55hsj9p60qmm5g8zmql2s";
  };
  ncurses-terminfo-base = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/ncurses-terminfo-base-6.4_p20231125-r0.apk";
    hash = "sha256:0h245xsz252rw7wx06zxqx646vx5nrnnm1swkbv9z8va4hpl57f8";
  };
  nghttp2-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/nghttp2-libs-1.58.0-r0.apk";
    hash = "sha256:07chyzdkd2l6y8fdl64f2qj7b27y4bq7xsf6br8rr69s4n04vgwn";
  };
  numactl = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/numactl-2.0.16-r4.apk";
    hash = "sha256:1r3mwa7s19wjicg2cgl42aib400ckvrjprh5q39r4cm2bjb678lw";
  };
  onevpl-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/onevpl-libs-2023.3.1-r2.apk";
    hash = "sha256:1vyvc5h0n9xn99j26m8drssn8x6ps2hcb972a7zr8c8bn2vjbrp5";
  };
  openexr-libiex = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/openexr-libiex-3.1.12-r0.apk";
    hash = "sha256:107w804p0y5spsznwibiva32sjv2vahhfn9pl7b04yjg6mlrdqwq";
  };
  openexr-libilmthread = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/openexr-libilmthread-3.1.12-r0.apk";
    hash = "sha256:1h70zdjaxn26a3hvfd8vz7yx5yv2zbm24xq0ky1val8xlrp91k7n";
  };
  openexr-libopenexr = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/openexr-libopenexr-3.1.12-r0.apk";
    hash = "sha256:0cisd8r1fsrz1xb0khjl63rs5y8zcra2acwajs3v770sqqakivld";
  };
  openexr-libopenexrcore = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/openexr-libopenexrcore-3.1.12-r0.apk";
    hash = "sha256:1f0ry8cafa5s1a2xhlkpgxrg92sbcvz6fjj3jirysq7fk6cyyay7";
  };
  openvpn = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/openvpn-2.6.11-r0.apk";
    hash = "sha256:16b8m294xhqh2ma0azk1nh9zc10yy0kda72hwik0axjhyk202p9h";
  };
  opus = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/opus-1.4-r0.apk";
    hash = "sha256:05pbq9ggcpvmrfxxxjzlzjdqkihw9l9ycyjdpr8kb2f5vg0yb1ff";
  };
  orc = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/orc-0.4.39-r0.apk";
    hash = "sha256:1h2mw9c6fh57hal8hnv2x9vmw9bqz2zc3233nxpivfwzimlwz6a6";
  };
  pcre2 = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/pcre2-10.42-r2.apk";
    hash = "sha256:16nsapgd6d3vp9vb7aa6apyv4jnc7x6jmjdkx0mk9i2f4c15nvys";
  };
  py3-certifi = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/py3-certifi-2024.2.2-r0.apk";
    hash = "sha256:073ryirvl5gajnl6yxwnvv3kap82c78z8wz4dv2nqcwk44v0qhx3";
  };
  py3-certifi-pyc = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/py3-certifi-pyc-2024.2.2-r0.apk";
    hash = "sha256:0zc5byxypxgwka8gnyp851kwc209xvbgs4xa7wqlps3kbf5a6lb7";
  };
  py3-charset-normalizer = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/py3-charset-normalizer-3.3.2-r0.apk";
    hash = "sha256:1zfsck6awi10pp1sdqbixcsdcn6hzf6v10zp1943w4a32znm2ym8";
  };
  py3-charset-normalizer-pyc = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/py3-charset-normalizer-pyc-3.3.2-r0.apk";
    hash = "sha256:0z2rfawi1qqa3l1zv97vr5xsgffh4hzrxsdzc7nb740dk42akc6g";
  };
  py3-idna = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/py3-idna-3.7-r0.apk";
    hash = "sha256:0w5ihkmi6qgny60bmgn3b8qgh9nw0w86jpmcxkzjf95plxxshpb5";
  };
  py3-idna-pyc = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/py3-idna-pyc-3.7-r0.apk";
    hash = "sha256:00s599w3rh3jlqvr4i7inwb7jil308nsvxkgjpxzw3208z8wd4f2";
  };
  py3-requests = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/py3-requests-2.32.3-r0.apk";
    hash = "sha256:0z0ssbm3hvbiph27cpdyjfgcvkrw9x3gnb6npar6krmdk1zx0gmc";
  };
  py3-requests-pyc = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/py3-requests-pyc-2.32.3-r0.apk";
    hash = "sha256:1b4cn6xrc84had7kgcrwh757d2iwzrj63j8hbgdlkdrjjm3azidg";
  };
  py3-urllib3 = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/py3-urllib3-1.26.18-r0.apk";
    hash = "sha256:0phcplbp0ky6paddg54w1606p75cw84766zpingwldj0lyg8z6f1";
  };
  py3-urllib3-pyc = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/py3-urllib3-pyc-1.26.18-r0.apk";
    hash = "sha256:10z8qz7zxgj557rrssg4h36zrr8c8d13k2gd6l0b680kbxkn2nm2";
  };
  pyc = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/pyc-3.11.12-r0.apk";
    hash = "sha256:1223dd5v6sn08ca0l45xph9x22fm4g9cqaqalxznwfslcyhvkqdn";
  };
  python3 = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/python3-3.11.12-r0.apk";
    hash = "sha256:0dbwlkpqkj3wgacz974sxawwgf4s703b1dfnhvmgmwchf8bkkqjp";
  };
  python3-pyc = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/python3-pyc-3.11.12-r0.apk";
    hash = "sha256:0rdyq833wh99gjs4r1yqs788v7an5f6ny48z4k97bcwgqamshbwk";
  };
  python3-pycache-pyc0 = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/python3-pycache-pyc0-3.11.12-r0.apk";
    hash = "sha256:0y9qdi9f4l4c1vlc2w96lf0s3jvxjf2d70m7m4wk3fqdrvblfn64";
  };
  rav1e-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/rav1e-libs-0.6.6-r2.apk";
    hash = "sha256:01zznsyiwwd1gs4i6lpp08dvzjphg4a76pgr56dpsac5zfpyvqps";
  };
  readline = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/readline-8.2.1-r2.apk";
    hash = "sha256:0r93faij4ir2wnkxja9f6pq8dlqppd2kpy35h0qk08ps56mxwmwb";
  };
  restic = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/restic-0.16.4-r2.apk";
    hash = "sha256:1mrrqbhav74wgr9gksljpgn0wyffw1z9px3i8qdc50dprqsx74qy";
  };
  sdl2 = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/sdl2-2.28.5-r0.apk";
    hash = "sha256:1pff8wsd7fb38866wh6k5dywypbvaqyr3nixypnrgz9w4vlgal37";
  };
  serd-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/serd-libs-0.32.0-r0.apk";
    hash = "sha256:1wdjm6p0jmb6pfjm1f11p1rnzjabyvl345cj3sf252r8y47q9xdm";
  };
  shaderc = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/shaderc-2023.7-r0.apk";
    hash = "sha256:0vg73pmznjia38lyi22fq7n0yk8zqbvc34qhr679izlifci2flxw";
  };
  sord-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/sord-libs-0.16.16-r0.apk";
    hash = "sha256:1p1hsxfy1rvnydlfh755frhk7mcj8xaky4qhw8i7xxscwb7y55dg";
  };
  soxr = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/soxr-0.1.3-r7.apk";
    hash = "sha256:1v09kaqc66y3h1f1f0517lrih5xhcfq4pjxqh1skh943xip7hpsx";
  };
  speexdsp = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/speexdsp-1.2.1-r2.apk";
    hash = "sha256:1m4jxm22dgn75v1jlrai45nfy72c503iah5s16y6ca1ys14yad9v";
  };
  spirv-tools = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/spirv-tools-1.3.261.1-r0.apk";
    hash = "sha256:0g8j4bg0aw5qr9v8lg619wqyxfhq3iykjkg09z011wm7aipgmvww";
  };
  sqlite-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/sqlite-libs-3.44.2-r1.apk";
    hash = "sha256:1wavxcpwijl8w8rcq3z3q0wlq4bvg6g2183pn1s05r3a88dgcb2f";
  };
  sratom = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/sratom-0.6.16-r0.apk";
    hash = "sha256:1j5k19jbshi5dc15b9sh1lynyfdwlf65iayqyh60i21i650j7wr5";
  };
  tdb-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/tdb-libs-1.4.9-r0.apk";
    hash = "sha256:1qyyw50l3vs5i2gw0wp2j858m2d0mz6x8mmxhv19wwynds9fwnfq";
  };
  unzip = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/unzip-6.0-r14.apk";
    hash = "sha256:0caicc5q55vkrh20gr3cha5ykpjjab4i8l4glx1xg40zny0kv21g";
  };
  v4l-utils-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/v4l-utils-libs-1.24.1-r1.apk";
    hash = "sha256:06113h1hp4fxm5a1w9q939djvq5q8fqpa4c5ax841z95nvmlzh5h";
  };
  vidstab = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/vidstab-1.1.1-r0.apk";
    hash = "sha256:0km69n4pz5wdcvgrh39vw7wrwpabzw6h2x4yn5w49w8y0kcz432x";
  };
  vulkan-loader = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/vulkan-loader-1.3.261.1-r0.apk";
    hash = "sha256:02187sx8mf2vkadzmqx1gqc64lc1s5x2zj3f478yr6vjk9zcazy0";
  };
  wayland-libs-client = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/wayland-libs-client-1.22.0-r4.apk";
    hash = "sha256:1zaqpyakh5h24zrjdxmdkfs7bn7w2dy0zh3xzwvsxymhnd58rs28";
  };
  x264-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/x264-libs-0.164_git20231001-r0.apk";
    hash = "sha256:1y57faqqff0bj9f2wygj5zk7mms66440lj7fzlgz2si9d0zskil9";
  };
  x265-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/x265-libs-3.5-r4.apk";
    hash = "sha256:010mnd8iq5yalbv8rrcbbfafl1crrjm89i5h7ma22xyf419a19jw";
  };
  xvidcore = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/xvidcore-1.3.7-r2.apk";
    hash = "sha256:01hc5y5hzkmcdymk59a9q2karp9g7axjfykwrhimwnbny1fg9r5k";
  };
  xz-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/xz-libs-5.4.5-r1.apk";
    hash = "sha256-oZnhFwZk7ZfY3YAjHRh8PYpCps1EufrZ5JGH1fxhyKI=";
  };
  zimg = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/zimg-3.0.5-r2.apk";
    hash = "sha256:0388ig7h448jv6dxnljnwvdpg7cw75d5dapr94azha7ck6ii176i";
  };
  zix-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/zix-libs-0.4.2-r0.apk";
    hash = "sha256:1f92jc3yd9j1nq0l1lkhd34lyl9qx64xh98a394jdbzkg93bmzvx";
  };
  zstd-libs = fetchurl {
    url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/zstd-libs-1.5.5-r8.apk";
    hash = "sha256:1rl0208vpd33igq5y2r0s7pazwq61i7264nrg1dy4lg8sj220ghd";
  };
}
