{ stamp, writeText }:

stamp.patch {
  name = "stamp-img-skaia-paperless";
  base = stamp.fetch {
    repository = "ghcr.io/paperless-ngx/paperless-ngx";
    digest = "sha256:ab72a0ab42a792228cdbe83342b99a48acd49f7890ae54b1ae8e04401fba24ee"; # tag "2.17"
    hash = "sha256-zqA/wweUFcZb5CV4HRzSCFTDguGFuAl6hvTzJBcBKlM=";
  };
  copy = [{
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
