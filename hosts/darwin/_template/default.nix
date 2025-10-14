{ pkgs, ... }:

#############################################################
#
#  HOSTNAME - DESCRIPTION
#  macOS Darwin Configuration
#
#############################################################

{
  imports = [
    # Uncomment optional modules as needed:
    # ../../common/optional/development.nix
  ];

  # Host identification
  networking.hostName = "HOSTNAME";
  networking.computerName = "HOSTNAME";
  system.defaults.smb.NetBIOSName = "HOSTNAME";

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # Add host-specific packages here
  ];

  # Host-specific settings
  # Add any machine-specific configuration here
}
