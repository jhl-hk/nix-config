{ ... }:

#############################################################
#
#  Homebrew Configuration
#  Common Homebrew packages for all macOS hosts
#
#############################################################

{
  homebrew = {
    taps = [
      "tw93/tap"
      "oven-sh/bun"
    ];

    # Command-line packages
    brews = [
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
