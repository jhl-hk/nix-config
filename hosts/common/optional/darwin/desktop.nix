{...}:
#############################################################
#
#  Desktop applications -- GUI casks and Mac App Store titles
#
#  Split out of hosts/common/core/darwin/apps.nix so a machine can be a
#  headless-ish development box without dragging in fifty GUI apps. Imported
#  by jhlsMacBookPro and SeandeMac-Studio; deliberately not by
#  jhlsMacBookAir.
#
#  WARNING: onActivation.cleanup = "zap" means dropping this import from a
#     host **uninstalls** every app below on the next switch. That is the
#     intended behaviour, but it is not a dry run -- an app holding local
#     state you care about should be backed up first.
#
#  masApps needs an Apple ID signed in (`mas signin your@email.com`) and is
#  skipped entirely on seed builds; see darwinHomebrew.macosBeta. `mas`
#  itself stays in core, so the CLI is available even where no App Store
#  titles are declared -- move it here too if that ever looks like waste.
#
#############################################################
{
  darwinHomebrew = {
    casks = [
      # Fonts
      "font-maple-mono" # Maple Mono Font
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
      "stats" # System status monitor
      "sublime-text" # Text editor
      "syncthing-app"
      "termius" # SSH client
      "visual-studio-code"
      "wireshark-app"
      "winbox" # Router management
      "yubico-authenticator" # YubiKey authenticator
      "wakatime"
      "datagrip"

      # Editors
      "antigravity" # Google's agentic IDE
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
