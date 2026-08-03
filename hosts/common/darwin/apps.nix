{ config, lib, ... }:

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
      extraFlags = [ "--force-cleanup" ];
    };

    # Homebrew 6.0 turned on HOMEBREW_REQUIRE_TAP_TRUST, so a non-official tap
    # has to be trusted before activation may load its formulae/casks. `trusted`
    # emits `trusted: true` into the Brewfile, which brew bundle applies before
    # the fetch phase -- no need to run `brew trust` by hand on a new machine.
    taps = [
      { name = "oven-sh/bun"; trusted = true; }
      { name = "theseal/ssh-askpass"; trusted = true; }
      { name = "tw93/tap"; trusted = true; }
      { name = "siderolabs/tap"; trusted = true; }
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
      "kubernetes-cli"
      "helm"
      "gh"
      "tokei"
      "tmux"

      # Networking & security
      "iperf3"
      "nexttrace"
      "sleuthkit"
      "ssh-askpass"
      "ykman"

      # Utilities
      "mole"  # Disk cleaner
      "awscli"         # AWS CLI
      "rclone"

      # AI
      "gemini-cli"
      "opencode"
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

      "notion"                   # Documentation
      "notion-calendar"
      "clash-verge-rev"
    ];

    # Mac App Store apps
    # Requires: Apple ID login (run: mas signin your@email.com)
    # Skipped on seed builds, where mas cannot install: set `local.macosBeta` in
    # the host's configuration (`just check-beta` reports which kind it is).
    masApps = lib.optionalAttrs (!config.local.macosBeta) {
      # "Yubico Authenticator" = 1497506650;  # YubiKey Auth App
      "Infuse" = 1136220934;                # Video Player
      "Apple Configurator" = 1037126344;
      "Line" = 539883307;
      "Xcode" = 497799835;
      "Texifier - LaTeX Editor" = 458866234;
      "MoneyWiz 2026 Personal Finance" = 1511185140;
    };
  };
}
