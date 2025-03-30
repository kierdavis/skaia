{ imageTools }:

imageTools.customise {
  base = imageTools.bases.alpine;
  add = [(imageTools.fetchAPKs {
    urls = [
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/ffmpeg-6.1.2-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/ffmpeg-libavcodec-6.1.2-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/ffmpeg-libavdevice-6.1.2-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/ffmpeg-libavfilter-6.1.2-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/ffmpeg-libavformat-6.1.2-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/ffmpeg-libavutil-6.1.2-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/ffmpeg-libpostproc-6.1.2-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/ffmpeg-libswresample-6.1.2-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/ffmpeg-libswscale-6.1.2-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/imath-3.1.12-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/intel-gmmlib-22.5.4-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/intel-media-driver-24.4.3-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libass-0.17.3-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libasyncns-0.8-r4.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libbluray-1.3.4-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libdeflate-1.22-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libdovi-3.3.1-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libhwy-1.0.7-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libjxl-0.10.3-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libopenmpt-0.7.12-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libplacebo-6.338.2-r3.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libpulse-17.0-r4.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/librist-0.2.10-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libsrt-1.5.3-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libssh-0.11.1-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libSvtAv1Enc-2.2.1-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libunibreak-6.1-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libva-utils-2.22.0-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/libvpx-1.15.0-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/lilv-libs-0.24.24-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/onevpl-libs-2023.3.1-r2.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/openexr-libiex-3.3.2-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/openexr-libilmthread-3.3.2-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/openexr-libopenexr-3.3.2-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/openexr-libopenexrcore-3.3.2-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/rav1e-libs-0.7.1-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/sdl2-2.30.9-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/serd-libs-0.32.2-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/shaderc-2024.0-r2.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/sord-libs-0.16.16-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/soxr-0.1.3-r7.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/sratom-0.6.16-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/v4l-utils-libs-1.28.1-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/vidstab-1.1.1-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/x264-libs-0.164.3108-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/x265-libs-3.6-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/xvidcore-1.3.7-r2.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/zimg-3.0.5-r2.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/community/x86_64/zix-libs-0.4.2-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/alsa-lib-1.2.12-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/aom-libs-3.11.0-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/brotli-libs-1.1.0-r2.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/cjson-1.7.18-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/dbus-libs-1.14.10-r4.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/fontconfig-2.15.0-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/freetype-2.13.3-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/fribidi-1.0.16-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/giflib-5.2.2-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/glib-2.82.5-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/glslang-libs-1.3.296.0-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/graphite2-1.3.14-r6.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/harfbuzz-9.0.0-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/hwdata-pci-0.390-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/lame-libs-3.100-r5.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/lcms2-2.16-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libblkid-2.40.4-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libbsd-0.12.2-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libbz2-1.0.8-r6.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libdav1d-1.5.0-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libdrm-2.4.123-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libeconf-0.6.3-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libexpat-2.6.4-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libffi-3.4.6-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libflac-1.4.3-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libgcc-14.2.0-r4.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libgomp-14.2.0-r4.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libintl-0.22.5-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libjpeg-turbo-3.0.4-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libltdl-2.4.7-r3.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libmd-1.1.0-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libmount-2.40.4-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libogg-1.3.5-r5.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libpciaccess-0.18.1-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libpng-1.6.44-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libsharpyuv-1.4.0-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libsndfile-1.2.2-r2.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libsodium-1.0.20-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libstdc++-14.2.0-r4.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libtheora-1.1.1-r18.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libva-2.22.0-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libvdpau-1.5-r4.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libvorbis-1.3.7-r2.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libwebp-1.4.0-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libwebpmux-1.4.0-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libx11-1.8.10-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libxau-1.0.11-r4.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libxcb-1.16.1-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libxdmcp-1.1.5-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libxext-1.3.6-r2.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libxfixes-6.0.1-r4.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libxml2-2.13.4-r3.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/libzmq-4.3.5-r2.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/mbedtls-3.6.2-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/mpg123-libs-1.32.9-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/numactl-2.0.18-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/opus-1.5.2-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/orc-0.4.40-r1.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/pcre2-10.43-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/speexdsp-1.2.1-r2.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/spirv-tools-1.3.296.0-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/tdb-libs-1.4.12-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/vulkan-loader-1.3.296.0-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/wayland-libs-client-1.23.1-r0.apk"
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/xz-libs-5.6.3-r0.apk"
    ];
    hash = "sha256-bCU+BCX2bWNWyG5QSr+2ObKRAbtmPojmT2dv3AWWfl4=";
  })];
  run = imageTools.installAPKs;
  newLayerHash = "sha256-l4ZVw8qNTdPYFjjdaibd0IPOGhomb06nBeSCzdf23C8=";
}
