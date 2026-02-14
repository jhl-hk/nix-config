{ pkgs, ... }:

#############################################################
#
#  HOSTNAME - DESCRIPTION
#  macOS Darwin Configuration
#
#############################################################

{
  imports = [
  ];

  # Host identification
  networking.hostName = "jhlsMacBookPro";
  networking.computerName = "jhlsMacBookPro";
  system.defaults.smb.NetBIOSName = "jhlsMacBookPro";

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # Add host-specific packages here
  ];

  # Host-specific settings
  # Add any machine-specific configuration here
}
