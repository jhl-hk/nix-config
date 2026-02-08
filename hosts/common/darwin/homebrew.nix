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
      "theseal/ssh-askpass"
    ];

    # Command-line packages
    brews = [
      # Language & Necessary
      "openssh"
      "gcc"        # Fortran
      "go"         # Golang
      "rust"
      "tree"
      "git"
      "bun"        # Package Manager
      "node"
      "openjdk"
      "nexttrace"
      "just"

      # Cyber Security
      "sleuthkit"

      # Tools
      "tw93/tap/mole"  # Disk Cleaner
      "neofetch"       # System Info
      "ykman"
      "iperf3"
      "ssh-askpass"
    ];

    # GUI Applications
    casks = [
      # Fonts
      "font-maple-mono"          # Maple Mono Font
      "font-source-han-sans-vf"

      # Development Tools
      "stats"                    # System Status Monitor
      "jordanbaird-ice"          # Menubar Management
      "yubico-authenticator"     # YubiKey Authenticator
      "clash-verge-rev"          # Clash VPN
      "termius"                  # SSH Client
      "winbox"                   # Router Management
      "sublime-text"             # Text Editor
      "intellij-idea"
      "webstorm"
      "rustdesk"
      "wireshark-app"
      "tailscale-app"            # VPN
      "1password"
      "arduino-ide"
      "syncthing-app"
      "visual-studio-code"
      "balenaetcher"
      "claude-code"
      "dockdoor"

      # Editors
      "typora"                   # Markdown Editor
      "zed"                      # Code Editor
      "notion"                   # Documentation
      "microsoft-office"
      "cursor"

      # Communication
      "wechat"
      "qq"
      "telegram"
      "discord"
      "voov-meeting"
      "lark"
      "zoom"
      "teamspeak-client"

      # Browsers
      "google-chrome"
      "firefox"

      "spotify"
      "steam"
    ];

    # Mac App Store apps
    # Requires: Apple ID login (run: mas signin your@email.com)
    # Not Compatible with Beta system
    masApps = {
      # "Yubico Authenticator" = 1497506650;  # YubiKey Auth App
      # "Infuse" = 1136220934;                # Video Player
    };
  };
}
