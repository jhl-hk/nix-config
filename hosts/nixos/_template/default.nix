{ config, pkgs, ... }:

#############################################################
#
#  HOSTNAME - DESCRIPTION
#  NixOS Configuration
#
#############################################################

{
  imports = [
    ./hardware-configuration.nix
    # Uncomment optional modules as needed:
    # ../../common/optional/development.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "HOSTNAME";
  networking.networkmanager.enable = true;

  # Timezone and locale
  time.timeZone = "America/New_York";  # Change as needed
  i18n.defaultLocale = "en_US.UTF-8";

  # System packages
  environment.systemPackages = with pkgs; [
    # Add host-specific packages here
  ];

  # Enable OpenSSH daemon
  services.openssh.enable = true;

  # NixOS release version
  system.stateVersion = "24.05";
}
