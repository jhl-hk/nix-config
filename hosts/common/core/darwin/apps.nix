{...}:
#############################################################
#
#  Homebrew manifest
#
#  Data only. The wiring, and the beta gate on masApps, live in
#  modules/hosts/darwin/homebrew/.
#
#  taps / brews / casks are listOf, so definitions from other modules
#  concatenate -- which is how hosts/common/optional/darwin/*.nix can each
#  append their own.
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
      # Installs and switches Xcode versions, including prereleases. Needed on
      # seed builds: Homebrew refuses to build any unbottled formula while
      # /Applications/Xcode.app is older than the running macOS. There is no
      # cask for Xcode itself (Apple forbids redistribution), and the old
      # homebrew/cask-versions xcode-beta was archived in 2024.
      "xcodes"
      "age-plugin-yubikey"

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
      "cloudflare-wrangler" # Cloudflare Workers/R2 CLI

      # Backing tools for the docx/pdf/pptx/xlsx skills linked in
      # home/jhl/common/core/claude.nix. Those skills are prose plus a few
      # scripts; every real operation shells out to something here.
      #
      #   pandoc   docx -> markdown, the "read a Word file" path
      #   qpdf     command-line merge/split/rotate/encrypt
      #   poppler  provides pdftotext
      #
      # uv is the odd one out and the reason there is no python3.withPackages
      # anywhere: the skills need openpyxl, pandas, pypdf, pdfplumber,
      # reportlab, pytesseract and markitdown, all of which nixpkgs has -- but
      # home/jhl/common/core/darwin.nix prepends /opt/homebrew/bin to PATH, so
      # a nix python would never win a bare `python3` lookup and the modules
      # would be invisible. Shadowing Homebrew's python@3.14 instead is not
      # an option either: awscli, openssh, ykman and ldns all depend on it.
      #
      # So the modules are fetched per-invocation instead:
      #   uv run --with openpyxl,pandas python script.py
      #   uvx markitdown deck.pptx
      # No global interpreter changes, nothing to keep in sync with brew.
      "pandoc"
      "qpdf"
      "poppler"
      "uv"

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
      "wechatwork"

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

    # Requires signing in to an Apple ID first: mas signin your@email.com
    # Skipped entirely on seed builds; see darwinHomebrew.macosBeta
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
