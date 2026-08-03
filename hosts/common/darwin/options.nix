{ lib, ... }:

#############################################################
#
#  Local Options
#  Per-host switches consumed by the common Darwin modules
#
#############################################################

{
  options.local.macosBeta = lib.mkEnableOption ''
    this host running a macOS beta/seed build.

    Nix evaluates purely and cannot see the host's OS version, so this has to be
    declared rather than detected. Run `just check-beta` on the machine to find
    out which it is.

    Mac App Store installs via `mas` are unreliable on seed builds, so setting
    this drops `homebrew.masApps` from the generated Brewfile
  '';
}
