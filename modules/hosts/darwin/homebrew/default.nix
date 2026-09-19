{
  config,
  lib,
  ...
}:
#############################################################
#
#  Homebrew
#
#  The capability layer: options and wiring only, no concrete package names.
#  The manifest data lives in hosts/common/core/darwin/apps.nix, and per-machine
#  additions in hosts/common/optional/darwin/*.nix.
#
#  taps / brews / casks are all listOf, so the module system **concatenates**
#  definitions from anywhere -- any number of optional files can append without
#  knowing about each other.
#
#  masApps is declared here but installed by ./mas.nix, outside brew bundle.
#  That file carries the why; the short version is that mas has to be decided
#  at activation time (seed builds cannot use it) and must not be able to
#  abort the Brewfile.
#
#############################################################
let
  cfg = config.darwinHomebrew;
  inherit (lib) mkOption types;
in {
  # Siblings inside modules/hosts/darwin/homebrew/ are NOT picked up by
  # scanPaths -- it stops at this directory's default.nix. Name them here.
  imports = [./mas.nix];

  options.darwinHomebrew = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Let nix-darwin manage Homebrew.";
    };

    taps = mkOption {
      type = types.listOf (types.either types.str (types.attrsOf types.anything));
      default = [];
      description = ''
        Taps to add.

        Since Homebrew 6.0, HOMEBREW_REQUIRE_TAP_TRUST is on by default, so a
        third-party tap must be trusted before its formulae/casks can load at
        activation time. Writing `{ name = "..."; trusted = true; }` emits
        `trusted: true` into the Brewfile, which brew bundle applies before
        fetching -- so a new machine needs no manual `brew trust`.
      '';
    };

    brews = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Command-line formulae.";
    };

    casks = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "GUI application casks.";
    };

    masApps = mkOption {
      type = types.attrsOf types.int;
      default = {};
      description = ''
        Mac App Store apps: key is the display name, value is the App ID.
        Requires signing in to an Apple ID first (`mas signin your@email.com`).

        Installed by ./mas.nix at activation time, not by brew bundle, so a
        machine on a macOS seed build skips them automatically and a failed
        install cannot take the rest of the Brewfile down with it. Also
        install-only: dropping an entry here does not uninstall the app.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    homebrew = {
      enable = true;

      onActivation = {
        autoUpdate = true;
        # Any Homebrew package not declared above is uninstalled on the next
        # switch. Anything from a manual `brew install` is temporary: declare
        # it or lose it.
        cleanup = "zap";
        extraFlags = ["--force-cleanup"];
      };

      inherit (cfg) taps brews casks;

      # Deliberately empty: ./mas.nix owns the App Store apps. Handing them
      # to brew bundle is what let a single failing `mas upgrade` skip the
      # zap cleanup for every tap, brew and cask.
      masApps = {};
    };
  };
}
