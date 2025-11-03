{ ... }:

#############################################################
#
#  Homebrew Configuration
#  Common Homebrew packages for all macOS hosts
#
#############################################################

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";  # Uninstall all programs not declared
    };

    taps = [
      "tw93/tap"
      "oven-sh/bun"
    ];

    # Command-line packages
    brews = [
      # Language & Neccessary
      "openssh"
      "gcc" # Fortran
      "go" # Golang
      "rust"
      "tree"
      "git"
      "bun" # Package Manager
      "node"
      "openjdk"

      # Cyber Security
      sleuthkit

      # Tools
      "tw93/tap/mole" # Disk Cleaner
      "neofetch" # System Info
    ];

    # GUI Applications
    casks = [
      # Fonts
      "font-maple-mono" # Maple Mono Font
      "font-source-han-sans-vf"
    ];

    # Mac App Store apps
    # Requires: Apple ID login (run: mas signin your@email.com)
    # Not Capatiable with Beta system
    masApps = {
      # "Yubico Authenticator" = 1497506650; # YubiKey Auth App
      # "Infuse" = 1136220934; # Video Player
    };
  };
}
