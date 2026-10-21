{pkgs, ...}:
#############################################################
#
#  Typst toolchain
#
#    typst      compiler (typst compile / watch)
#    tinymist   language server; the Zed typst extension in
#               optional/editors/zed.nix picks it up from PATH
#    typstyle   formatter
#
#############################################################
{
  home.packages = with pkgs; [
    typst
    tinymist
    typstyle
  ];
}
