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
      "pnpm"
      "npm"
      "node"
      "openjdk"

      # Tools
      "tw93/tap/mole" # Disk Cleaner
      "neofetch" # System Info
      # "mas" # Mac App Store CLI
      "tailscale" # VPN
    ];

    # GUI Applications
    casks = [
      # Tools
      "stats"  # System Status Monitor
      "jordanbaird-ice" # Menubar Management
      "yubico-authenticator" # YubiKey Authenticator
      "clash-verge-rev" # Clash
      "termius" # SSH Client
      "winbox" # Router Management
      "sublime-text" # Text Editor
      "claude" # AI Tool

      # Editors
      "typora" # Markdown Editor
      "zed" # Code Editor
      "notion" # Documentation

      # SNS Applications
      "wechat"
      "qq"
      "telegram"

      # Browser
      "google-chrome"
      "firefox"

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
