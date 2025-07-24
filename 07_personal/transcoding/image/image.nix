{ ffmpeg, intel-media-driver, lib, libva-utils, stamp }:

stamp.fromNix {
  name = "stamp-img-skaia-transcoding";
  runOnHost = ''
    mkdir -p run/opengl-driver/lib/dri
    ln -sf ${intel-media-driver}/lib/dri/iHD_drv_video.so -t run/opengl-driver/lib/dri
  '';
  env.PATH = lib.makeBinPath [ ffmpeg libva-utils ];
}
