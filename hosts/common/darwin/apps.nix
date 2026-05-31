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
      "siderolabs/tap"
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
      "wails"

      # Core tools
      "git"
      "just"
      "openssh"
      "tree"
      "telnet"
      "mas"
      "talosctl"

      # Networking & security
      "iperf3"
      "nexttrace"
      "sleuthkit"
      "ssh-askpass"
      "ykman"

      # Utilities
      "neofetch"       # System info
      "tw93/tap/mole"  # Disk cleaner
      "awscli"         # AWS CLI
      "rclone"

      # AI
      "gemini-cli"
    ];

    # GUI Applications
    casks = [
      # Fonts
      "font-maple-mono"          # Maple Mono Font
      "font-source-han-sans-vf"

      "notchnook"
      "alt-tab"
      "claude"

      # Development Tools
      "1password"
      "arduino-ide"
      "balenaetcher"
      "bartender"
      "intellij-idea"
      "rustdesk"
      "stats"                    # System status monitor
      "sublime-text"             # Text editor
      "syncthing-app"
      "tailscale-app"            # VPN
      "termius"                  # SSH client
      "visual-studio-code"
      "wireshark-app"
      "winbox"                   # Router management
      "yubico-authenticator"     # YubiKey authenticator
      "wakatime"
      "datagrip"

      # Editors
      "cursor"
      "microsoft-office"
      "notion"                   # Documentation
      "typora"                   # Markdown editor
      "zed"                      # Code editor
      "webstorm"
      "goland"
      "mactex"
      "dbeaver-community"

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
      "google-chrome"

      "google-drive"

      # Media & games
      "spotify"

      # AI
      "claude-code"
      "codex"
      "grammarly-desktop"
    ];

    # Mac App Store apps
    # Requires: Apple ID login (run: mas signin your@email.com)
    # Not Compatible with Beta system
    masApps = {
      # "Yubico Authenticator" = 1497506650;  # YubiKey Auth App
      "Infuse" = 1136220934;                # Video Player
      "Apple Configurator" = 1037126344;
      "Line" = 539883307;
      "Xcode" = 497799835;
      "Texifier - LaTeX Editor" = 458866234;
    };
  };
}
