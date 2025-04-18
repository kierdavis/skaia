{ imageTools, writeText }:

# After a thouroughly painful troubleshooting session, I found that this fixes
# the garbled text in the PDF/A files produced from newer Jump paychecks.
#
# The input PDFs use the Arial font without embedding it, and by default
# ghostscript resolves this its builtin Nimbus Sans font, which apparantly sucks.
#
# We'll use Liberation Sans instead. It's installed in the image but we need to
# alter ghostscript's config to direct it towards this font rather than Nimbus.
#
# If we just map Arial (& Bold) but not Helvetica, ghostscript crashes.
# I assume this is something to do with the fact the default config first
# de-aliases Arial to Helvetica and then de-aliases Helvetica to Nimbus Sans.

imageTools.customise {
  base = imageTools.fetch {
    imageName = "ghcr.io/paperless-ngx/paperless-ngx";
    imageDigest = "sha256:da0476cea301df8bc8d20739f0e76de1e77d91ad2c9170b45c803468dde19208";
    hash = "sha256-MqKoUUVzACkQtGicuTxpR42xT6Ap4Lq1mMQZ5lG4nM0=";
  };
  add = [{
    src = writeText "myfontmap.gs" ''
      /Arial,BoldItalic (/usr/share/fonts/truetype/liberation/LiberationSans-BoldItalic.ttf) ;
      /Arial,Bold (/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf) ;
      /Arial,Italic (/usr/share/fonts/truetype/liberation/LiberationSans-Italic.ttf) ;
      /Arial (/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf) ;
      /Helvetica (/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf) ;
    '';
    dest = "/usr/share/ghostscript/myfontmap.gs";
  }];
  env.GS_OPTIONS = "-sFONTMAP=/usr/share/ghostscript/myfontmap.gs";
}
