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
      "oven-sh/bun"
      "theseal/ssh-askpass"
      "tw93/tap"
    ];

    # Command-line packages
    brews = [
      # Languages & build tooling
      "bun"        # Package manager
      "gcc"        # Fortran
      "go"         # Golang
      "node"
      "openjdk"
      "rust"

      # Core tools
      "git"
      "just"
      "openssh"
      "tree"

      # Networking & security
      "iperf3"
      "nexttrace"
      "sleuthkit"
      "ssh-askpass"
      "ykman"

      # Utilities
      "neofetch"       # System info
      "tw93/tap/mole"  # Disk cleaner
    ];

    # GUI Applications
    casks = [
      # Fonts
      "font-maple-mono"          # Maple Mono Font
      "font-source-han-sans-vf"

      # Development Tools
      "1password"
      "arduino-ide"
      "balenaetcher"
      "bartender"
      "clash-verge-rev"          # Clash VPN
      "intellij-idea"
      "rustdesk"
      "stats"                    # System status monitor
      "sublime-text"             # Text editor
      "syncthing-app"
      "tailscale-app"            # VPN
      "termius"                  # SSH client
      "visual-studio-code"
      "webstorm"
      "wireshark-app"
      "winbox"                   # Router management
      "yubico-authenticator"     # YubiKey authenticator

      # Editors
      "cursor"
      "microsoft-office"
      "notion"                   # Documentation
      "typora"                   # Markdown editor
      "zed"                      # Code editor

      # Communication
      "discord"
      "lark"
      "qq"
      "teamspeak-client"
      "telegram"
      "voov-meeting"
      "wechat"
      "zoom"

      # Browsers
      "firefox"
      "google-chrome"

      # Media & games
      "spotify"
      "steam"
    ];

    # Mac App Store apps
    # Requires: Apple ID login (run: mas signin your@email.com)
    # Not Compatible with Beta system
    masApps = {
      # "Yubico Authenticator" = 1497506650;  # YubiKey Auth App
      "Infuse" = 1136220934;                # Video Player
    };
  };
}
