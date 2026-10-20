{
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  Yazi -- terminal file manager
#
#  https://yazi-rs.github.io/docs/installation
#
#  The preview and search dependencies upstream lists (file, ffmpeg, 7zz, jq,
#  poppler, fd, ripgrep, fzf, zoxide, resvg, imagemagick) are not installed
#  here: the nixpkgs yazi package is a wrapper that already puts all of them on
#  its own PATH. Only the Linux clipboard tool is missing from that set.
#
#  `y` is the shell wrapper: it runs yazi and cd's the shell to wherever yazi
#  was when it quit. Plain `yazi` still works and leaves the cwd alone.
#
#  Icons need Nerd Font glyphs. Ghostty on the Macs ships them built in, so
#  only the Linux side gets the symbols-only font as a fontconfig fallback.
#
#############################################################
{
  home.packages = lib.optionals pkgs.stdenv.isLinux [pkgs.nerd-fonts.symbols-only];

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    shellWrapperName = "y";

    extraPackages = lib.optionals pkgs.stdenv.isLinux [pkgs.wl-clipboard];

    settings.mgr.show_hidden = true;
  };
}
