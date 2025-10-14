{ ... }:

#############################################################
#
#  macOS System Defaults
#  Common system preferences for all macOS hosts
#
#  All options documented here:
#  https://daiderd.com/nix-darwin/manual/index.html#sec-options
#
#############################################################

{
  system.defaults = {
    # Menu bar
    menuExtraClock.Show24Hour = true;  # Show 24 hour clock

    # Dock settings
    dock = {
      autohide = true;
      show-recents = false;
      launchanim = true;
      orientation = "bottom";
      tilesize = 48;
    };

    # Finder settings
    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      FXEnableExtensionChangeWarning = false;
    };

    # Trackpad settings
    trackpad = {
      Clicking = true;  # Enable tap to click
      TrackpadRightClick = true;
    };

    # NSGlobalDomain settings
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";  # Dark mode
      KeyRepeat = 2;
    };
  };
}
