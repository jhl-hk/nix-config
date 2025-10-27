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

  # Intel Mac uses different Homebrew paths than Apple Silicon
  environment.systemPath = [
    "/usr/local/bin"
    "/usr/local/sbin"
    "/usr/local/opt/openssh/bin"
  ];

  # Host-specific settings
  # Add any machine-specific configuration here
}
