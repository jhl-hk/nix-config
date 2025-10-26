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
  system = {
    startup.chime = false;

    defaults = {
      # Menu bar
      menuExtraClock.Show24Hour = true;  # Show 24 hour clock

      # Dock settings
      dock = {
        autohide = true;
        show-recents = true;
        launchanim = true;
        orientation = "bottom";
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

      # Calendar settings
      iCal = {
        "first day of week" = "Sunday";
        "TimeZone support enabled" = true;
        CalendarSidebarShown = true;
      };

      # Login Window settings
      loginwindow = {
        GuestEnabled = false;
      };

      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
    };
  };

  networking = {
    knownNetworkServices = [
      "Wi-Fi"
      "Ethernet"
    ];

    dns = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };
}
