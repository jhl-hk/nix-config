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
      "mas"            # Mac App Store CLI
    ];

    # GUI Applications
    casks = [
      "stats"  # System Status Monitor
    ];

    # Mac App Store apps
    # Requires: Apple ID login (run: mas signin your@email.com)
    masApps = {
      "Yubico Authenticator" = 1497506650; # YubiKey Auth App
      "Infuse" = 1136220934; # Video Player
    };
  };
}
