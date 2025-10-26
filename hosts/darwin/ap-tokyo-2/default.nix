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

  # Disable desktop applications for this host (server use only)
  # Override the common homebrew casks and brews configuration
  homebrew = {
    # Disable all casks (no desktop applications)
    casks = [];

    # Override brews list - remove bun and mole which have issues on Intel Mac
    brews = [
      # Language & Necessary
      "openssh"
      "gcc"
      "go"
      "rust"
      "tree"
      "git"
      "node"
      "openjdk"

      # Tools
      "neofetch"
      # Removed: "bun" - has permission issues on Intel Mac
      # Removed: "tw93/tap/mole" - not needed on server
    ];

    # Disable taps that are not needed
    taps = [];
  };

  # Host-specific settings
  # Add any machine-specific configuration here
}
