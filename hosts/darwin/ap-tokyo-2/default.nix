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

  # Intel Mac Homebrew paths (different from Apple Silicon)
  environment.systemPath = [
    "/usr/local/bin"
    "/usr/local/sbin"
    "/usr/local/opt/openssh/bin"
  ];

  # Disable desktop applications for this host (server use only)
  # Override the common homebrew casks configuration
  homebrew = {
    casks = [
      # No desktop applications for this server host
      # Only CLI tools from brews are installed (defined in common/darwin/homebrew.nix)
    ];

    # Disable problematic brews that may not be needed for server
    brews = [
      # Language & Necessary
      "openssh"
      "gcc" # Fortran
      "go" # Golang
      "rust"
      "tree"
      "git"
      "node"
      "openjdk"

      # Tools
      "neofetch" # System Info
      "tailscale" # VPN

      # Note: Removed bun and tw93/tap/mole which may cause issues on Intel
    ];

    # Disable taps that are not needed
    taps = [];
  };

  # Host-specific settings
  # Add any machine-specific configuration here
}
