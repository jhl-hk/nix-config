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

    # Colemak navigation, same scheme as ./vim.nix: h/n/e/i are
    # left/down/up/right. Prepended, so the QWERTY defaults still work as a
    # fallback. Keys displaced from n: find next/prev moves to k/K.
    # [input] and [confirm] keep their defaults.
    keymap = let
      vert = [
        {
          on = "n";
          run = "arrow next";
          desc = "Next";
        }
        {
          on = "e";
          run = "arrow prev";
          desc = "Previous";
        }
      ];
    in {
      mgr.prepend_keymap =
        vert
        ++ [
          {
            on = "h";
            run = "leave";
            desc = "Back to the parent directory";
          }
          {
            on = "i";
            run = "enter";
            desc = "Enter the child directory";
          }
          {
            on = "H";
            run = "back";
            desc = "Back to previous directory";
          }
          {
            on = "I";
            run = "forward";
            desc = "Forward to next directory";
          }
          {
            on = "E";
            run = "seek -5";
            desc = "Seek up 5 units in the preview";
          }
          {
            on = "N";
            run = "seek 5";
            desc = "Seek down 5 units in the preview";
          }
          {
            on = "k";
            run = "find_arrow";
            desc = "Next found";
          }
          {
            on = "K";
            run = "find_arrow --previous";
            desc = "Previous found";
          }
        ];
      tasks.prepend_keymap = vert;
      pick.prepend_keymap = vert;
      help.prepend_keymap = vert;
      spot.prepend_keymap =
        vert
        ++ [
          {
            on = "h";
            run = "swipe prev";
            desc = "Swipe to previous file";
          }
          {
            on = "i";
            run = "swipe next";
            desc = "Swipe to next file";
          }
        ];
    };
  };
}
