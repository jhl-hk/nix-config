{...}:
#############################################################
#
#  Homebrew 清单
#
#  只有数据。接线和 masApps 的 beta 门控在
#  modules/hosts/darwin/homebrew/。
#
#  taps / brews / casks 是 listOf，跟其它模块的定义会拼接，
#  所以 hosts/common/optional/darwin/*.nix 可以各自往里加。
#
#############################################################
{
  darwinHomebrew = {
    taps = [
      {
        name = "oven-sh/bun";
        trusted = true;
      }
      {
        name = "theseal/ssh-askpass";
        trusted = true;
      }
      {
        name = "tw93/tap";
        trusted = true;
      }
      {
        name = "siderolabs/tap";
        trusted = true;
      }
    ];

    brews = [
      # Languages & build tooling
      "bun" # Package manager
      "gcc" # Fortran
      "go" # Golang
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
      "kubernetes-cli"
      "helm"
      "gh"
      "tokei"
      "tmux"
      "kubelogin"

      # Networking & security
      "iperf3"
      "nexttrace"
      "sleuthkit"
      "ssh-askpass"
      "ykman"

      # Utilities
      "mole" # Disk cleaner
      "awscli" # AWS CLI
      "rclone"

      # AI
      "gemini-cli"
      "opencode"
    ];

    casks = [
      # Fonts
      "font-maple-mono" # Maple Mono Font
      "font-source-han-sans-vf"

      "notchnook"
      "alt-tab"
      "claude"
      "ghostty"

      # Development Tools
      "1password"
      "arduino-ide"
      "balenaetcher"
      "bartender"
      "intellij-idea"
      "rustdesk"
      "stats" # System status monitor
      "sublime-text" # Text editor
      "syncthing-app"
      "tailscale-app" # VPN
      "termius" # SSH client
      "visual-studio-code"
      "wireshark-app"
      "winbox" # Router management
      "yubico-authenticator" # YubiKey authenticator
      "wakatime"
      "datagrip"

      # Editors
      "cursor"
      "microsoft-office"
      "typora" # Markdown editor
      "zed" # Code editor
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
      "whatsapp"

      # Browsers
      "google-chrome"

      "google-drive"
      "windows-app"

      # Media & games
      "spotify"

      # AI
      "claude-code"
      "codex"
      "grammarly-desktop"

      "notion" # Documentation
      "notion-calendar"
      "clash-verge-rev"
    ];

    # 需要先登录 Apple ID：mas signin your@email.com
    # seed 版本上会被整个忽略，见 darwinHomebrew.macosBeta
    masApps = {
      # "Yubico Authenticator" = 1497506650;  # YubiKey Auth App
      "Infuse" = 1136220934; # Video Player
      "Apple Configurator" = 1037126344;
      "Line" = 539883307;
      "Xcode" = 497799835;
      "Texifier - LaTeX Editor" = 458866234;
      "MoneyWiz 2026 Personal Finance" = 1511185140;
    };
  };
}
