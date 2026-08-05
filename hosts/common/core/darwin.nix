{
  config,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  Darwin Core
#  Shared by every macOS machine. Selected by platform in
#  hosts/common/core/default.nix.
#
#############################################################
{
  imports = [
    ./darwin/system-defaults.nix
    ./darwin/apps.nix
  ];

  # nix-darwin wants an **integer**. NixOS wants a string for
  # system.stateVersion; mixing them up is a type error at evaluation time.
  # This value tracks the version at *initial install* -- do not bump it
  # without reading the nix-darwin release notes. It pins migration logic,
  # not the running version.
  system.stateVersion = 6;

  # All three hostname settings come from hostSpec; a host file only needs to
  # set hostSpec.hostName.
  networking = {
    hostName = config.hostSpec.hostName;
    computerName = config.hostSpec.hostName;
  };
  system.defaults.smb.NetBIOSName = config.hostSpec.hostName;

  # On Darwin this is nix.optimise.automatic, not auto-optimise-store
  nix.optimise.automatic = true;

  # Touch ID for sudo.
  # This is the **fallback layer** of the auth chain: machines with
  # darwinYubikey enabled slot a pam_u2f line in front of this one
  # (see modules/hosts/darwin/yubikey), and fall through to here when the
  # YubiKey is absent or untouched. Both lines are sufficient, and the
  # system password still sits below them.
  security.pam.services.sudo_local.touchIdAuth = true;

  # Generates /etc/zshrc, which loads the nix-darwin environment
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # Turn off the default compinit and let home-manager handle it, so nix
    # store paths don't trip the insecure-directory check
    enableGlobalCompInit = false;
    promptInit = ''
      eval "$(${pkgs.starship}/bin/starship init zsh)"
    '';
  };

  # Homebrew's paths need to be on the system PATH.
  #
  # The position matters: it has to sit between the nix paths and /usr/bin.
  #   ahead of nix       -> brew's git/openssh shadow nix's
  #   behind /usr/bin    -> Xcode's /usr/bin/git shadows brew's
  #
  # nix-darwin defines these in two passes in
  # modules/environment/default.nix:139:
  #   nix profiles     default order 1000
  #   the /usr/bin set mkOrder 1200
  # A plain definition is also 1000, and same-order definitions sort by module
  # position -- reordering imports breaks it (observed in practice).
  # mkOrder 1100 pins it in the middle, independent of module order.
  environment.systemPath = lib.mkOrder 1100 [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/opt/homebrew/opt/openssh/bin"
  ];

  environment.systemPackages = with pkgs; [
    starship

    # Omni CLI. Not via Homebrew: siderolabs/tap's omnictl ships no bottle, so
    # brew treats it as build-from-source and hits the Xcode version check on
    # macOS seed builds. unstable has 1.9.3, the same version as the tap.
    unstable.omnictl
  ];

  # Wallpaper. A plain assignment in a host file overrides it
  # (modules/hosts/darwin/wallpaper).
  darwinWallpaper = lib.mkDefault (lib.custom.relativeToRoot "assets/bg.jpeg");
}
