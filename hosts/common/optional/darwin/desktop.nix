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
#  skipped automatically on seed builds -- modules/hosts/darwin/homebrew/mas.nix
#  installs these outside brew bundle and checks sw_vers first. `mas` itself
#  stays in core, so the CLI is available even where no App Store titles are
#  declared -- move it here too if that ever looks like waste.
#
#  The JetBrains IDEs used to be in the lists below and are now their own
#  optional, hosts/common/optional/darwin/jetbrains.nix, imported by no
#  host. Add them back there, not here, so a machine can decline them.
#
#############################################################
{
  darwinHomebrew = {
    casks = [
      # Fonts
      "font-maple-mono" # Maple Mono Font
      "font-source-han-sans-vf"

      "claude"

      # Development Tools
      "1password"
      "arduino-ide"
      "balenaetcher"
      "rustdesk"
      "stats" # System status monitor
      "sublime-text" # Text editor
      "termius" # SSH client
      "wireshark-app"
      "winbox" # Router management
      "yubico-authenticator" # YubiKey authenticator
      "wakatime"

      # Editors
      "antigravity" # Google's agentic IDE
      # Office apps one by one: the microsoft-office suite cask always
      # installs OneNote too, with no way to leave it out.
      "microsoft-word"
      "microsoft-excel"
      "microsoft-powerpoint"
      "microsoft-outlook"
      "typora" # Markdown editor
      "zed" # Code editor
      "mactex"
      "dbeaver-community"

      # Communication
      "discord"
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
      "firefox"

      "google-drive"
      "windows-app"

      # Media & games
      "spotify"

      # AI
      "claude-code"
      "codex"
      "grok-build" # config inherited from ~/.claude, see home/jhl/common/core/grok.nix
      "grammarly-desktop"

      "notion" # Documentation
      "notion-calendar"
      "clash-verge-rev"
    ];

    # Requires signing in to an Apple ID first: mas signin your@email.com
    # Install-only, and skipped on seed builds: see
    # modules/hosts/darwin/homebrew/mas.nix. Deleting a line here does not
    # uninstall the app.
    masApps = {
      # "Yubico Authenticator" = 1497506650;  # YubiKey Auth App
      "Infuse" = 1136220934; # Video Player
      "Apple Configurator" = 1037126344;
      "Xcode" = 497799835;
      "Line" = 539883307;
      "Texifier - LaTeX Editor" = 458866234;
      "MoneyWiz 2026 Personal Finance" = 1511185140;
    };
  };
}
