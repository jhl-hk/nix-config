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
      "tw93/tap/mole"  # Disk Cleaner
      "neofetch"       # System Info
      "openssh"
    ];

    # GUI Applications
    casks = [
      "stats"  # System Status Monitor
    ];

    # Mac App Store apps
    masApps = {
      # Example: "Xcode" = 497799835;
    };
  };
}
