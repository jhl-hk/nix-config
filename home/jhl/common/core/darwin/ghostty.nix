{...}:
#############################################################
#
#  Ghostty
#
#  First nix-managed Ghostty config in this repo -- the terminal has been a
#  fleet-wide cask since it moved into hosts/common/core/darwin/apps.nix, but
#  its configuration was never managed. There was nothing to migrate:
#  ~/.config/ghostty did not exist, so this file is not overriding hand-written
#  settings.
#
#  -- Why it exists: trackpad scrolling in pi ----------------------------
#
#  pi runs in its default `--tui-mode regular`, which does not use the
#  alternate screen. So the transcript lands in Ghostty's own scrollback and
#  the *terminal*, not pi, decides how far a scroll gesture moves. Ghostty's
#  default is
#
#      mouse-scroll-multiplier = precision:1,discrete:3
#
#  -- one line per unit for precision devices (the trackpad) against three for
#  a discrete mouse wheel. That is what "one line at a time" is.
#
#  Worth knowing before chasing this in pi: pi's fullscreen mode has its own,
#  separate one-line step (pi-tui's wheelScrollLines, `?? 1`), which upstream
#  lowered from three deliberately and does **not** expose as a setting -- it
#  is not a settings.json key and pi never passes the option. If this machine
#  ever runs `--tui-mode fullscreen`, this file will not help and the only
#  lever is binding tui.altScreen.halfPageUp/halfPageDown in
#  ~/.pi/agent/keybindings.json, which ship unbound.
#
#  -- Scope, stated plainly ----------------------------------------------
#
#  This is a terminal-wide setting, not a pi one. Every full-screen program
#  scrolled in Ghostty gets the same multiplier. That is the trade for fixing
#  it here; the alternative -- pi-side -- does not exist for regular mode.
#
#  3 rather than some larger number: it simply makes the trackpad match what a
#  discrete wheel already does by default, so the two input devices stop
#  disagreeing. Valid range is [0.01, 10000]; the prefix syntax needs Ghostty
#  >= 1.2.1 (1.3.1 here).
#
#  -- Two things the home-manager module gets right only if told -----------
#
#  package = null is load-bearing. The module installs pkgs.ghostty by
#  default, and Ghostty here is the Homebrew cask in apps.nix -- leaving the
#  default would put a second, nix-built copy in the user profile shadowing
#  nothing and updating on a different schedule. Setting it null also turns
#  off the module's +validate-config check and its bat/vim syntax extras,
#  which all key off the package being present.
#
#  The module writes ${config.xdg.configHome}/ghostty/config, i.e.
#  ~/.config/ghostty/config. Ghostty on macOS also reads
#  ~/Library/Application Support/com.mitchellh.ghostty/config, so the XDG path
#  being the one that works here was worth checking rather than assuming --
#  verified with a temporary file:
#
#    ghostty +show-config | grep mouse-scroll-multiplier
#      mouse-scroll-multiplier = precision:5,discrete:3
#
#  A read-only store symlink is safe: Ghostty reads this file and never writes
#  it back. Its "Open Configuration" menu item opens it in an editor rather
#  than editing it in-app, so there is no settings UI to lose changes from.
#
#############################################################
{
  programs.ghostty = {
    enable = true;

    # See the header -- the binary is the Homebrew cask, not nixpkgs.
    package = null;

    settings = {
      mouse-scroll-multiplier = "precision:3,discrete:3";
    };
  };
}
