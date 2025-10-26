{ pkgs, ... }:

#############################################################
#
#  ap-tokyo-2 - Intel Mac Server
#  macOS Darwin Configuration
#
#############################################################

{
  imports = [
    # Host-specific configurations
  ];

  # Host identification
  networking.hostName = "ap-tokyo-2";
  networking.computerName = "ap-tokyo-2";
  system.defaults.smb.NetBIOSName = "ap-tokyo-2";

  # Disable desktop applications for this host (server use only)
  # Override the common homebrew casks configuration
  homebrew = {
    casks = [
      # No desktop applications for this server host
      # Only CLI tools from brews are installed (defined in common/darwin/homebrew.nix)
    ];
  };

  # Host-specific settings
  # Add any machine-specific configuration here
}
