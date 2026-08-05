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
#############################################################
let
  cfg = config.darwinHomebrew;
  inherit (lib) mkOption types;
in {
  options.darwinHomebrew = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Let nix-darwin manage Homebrew.";
    };

    macosBeta = mkOption {
      type = types.bool;
      default = false;
      description = ''
        This machine runs a macOS beta / seed build.

        Nix evaluates purely and cannot see the host's OS version, so this has
        to be declared rather than detected. Run `just check-beta` on the
        machine to find out which kind it is.

        mas installs from the Mac App Store are unreliable on seed builds, so
        turning this on drops masApps entirely from the generated Brewfile.
      '';
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
        Ignored entirely when macosBeta = true.
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

      masApps = lib.optionalAttrs (!cfg.macosBeta) cfg.masApps;
    };
  };
}
