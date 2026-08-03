{ pkgs, ... }:

#############################################################
#
#  HOSTNAME - DESCRIPTION
#  macOS Darwin Configuration
#
#############################################################

{
  # Host identification
  networking.hostName = "SeandeMac-Studio";
  networking.computerName = "SeandeMac-Studio";
  system.defaults.smb.NetBIOSName = "SeandeMac-Studio";

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # Add host-specific packages here
  ];

  # Host-specific settings
  # macOS 27.0 (26A5388g), enrolled in the 27seed catalog
  local.macosBeta = true;
}
