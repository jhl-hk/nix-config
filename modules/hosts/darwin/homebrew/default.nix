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

    cleanup = mkOption {
      type = types.enum ["none" "uninstall" "zap"];
      default = "zap";
      description = ''
        What to do on activation with Homebrew packages this repo does not
        declare.

        `zap` uninstalls them **and deletes their configuration and data**.
        That is the fleet default because it is what makes the Brewfile the
        single source of truth: a manual `brew install` is temporary, declare
        it or lose it.

        `uninstall` still removes undeclared packages but leaves their files
        alone, so reinstalling one finds its settings intact. `none` disables
        cleanup entirely, which also means the machine's Homebrew state stops
        being readable from this repo.

        Worth lowering on a machine where an undeclared package is load-bearing
        for reaching the machine at all -- a VPN, an input method -- since zap
        would take its state with it.
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
        # it or lose it. Per-host, because "lose it" is not equally cheap
        # everywhere -- see the option's description.
        inherit (cfg) cleanup;
        extraFlags = ["--force-cleanup"];
      };

      inherit (cfg) taps brews casks;

      masApps = lib.optionalAttrs (!cfg.macosBeta) cfg.masApps;
    };
  };
}
