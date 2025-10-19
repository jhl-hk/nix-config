{ pkgs, ... }:

#############################################################
#
#  MacBook Air - jhlsMacBookAir
#  macOS Darwin Configuration
#
#############################################################

{
  imports = [
    # Host-specific configurations
  ];

  # Host identification
  networking.hostName = "jhlsMacBookAir";
  networking.computerName = "jhlsMacBookAir";
  system.defaults.smb.NetBIOSName = "jhlsMacBookAir";

  # Host-specific settings
  # Add any machine-specific configuration here
  # Homebrew
  homebrew = {
    casks = [
      "google-drive"
    ];
  };
}
