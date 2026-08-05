{config, ...}:
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

    # The wallpaper moved to modules/hosts/darwin/wallpaper -- this file and
    # jhlsMacBookAir each used to write their own postActivation.text, and
    # both fragments ran.

    defaults = {
      # Menu bar clock
      menuExtraClock = {
        Show24Hour = true; # 24-hour clock
        ShowAMPM = true; # only applies in 12-hour mode; kept at its current value
        ShowDayOfWeek = true; # show the weekday
        ShowDate = 0; # 0 = when space permits, 1 = always, 2 = never
      };

      # Control Center / menu bar icons
      controlcenter.BatteryShowPercentage = true;

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
        Clicking = true; # Enable tap to click
        TrackpadRightClick = true;
      };

      # NSGlobalDomain settings
      NSGlobalDomain = {
        AppleICUForce24HourTime = true;
        AppleInterfaceStyle = "Dark"; # Dark mode
        _HIHideMenuBar = false; # don't auto-hide the menu bar
        # Keyboard-related keys live in home/jhl/common/core/darwin/keyboard.nix
      };

      # The remaining menu bar switches, for which nix-darwin has no typed
      # option.
      #
      # Each com.apple.controlcenter module is a bit field, not a boolean:
      #   2  = show when active
      #   8  = don't show in the menu bar
      #   18 = always show in the menu bar  (= 16 | 2)
      #   24 = explicitly set to hidden     (= 16 | 8)
      # nix-darwin's system.defaults.controlcenter.* only ever writes 18 or 24,
      # so using it would flip Sound/Display/NowPlaying from "show when active"
      # to "always in the menu bar". Hence the raw values here. Module state
      # lives in the ByHost plist, at the same path nix-darwin itself uses when
      # writing controlcenter.
      CustomUserPreferences = {
        "~${config.system.primaryUser}/Library/Preferences/ByHost/com.apple.controlcenter" = {
          Sound = 2;
          Display = 2;
          NowPlaying = 2;
          Bluetooth = 8;
          FocusModes = 8;
          Spotlight = 8;
          VoiceControl = 8;
          UserSwitcher = 24;
        };

        # This key does not live in the ByHost domain
        "com.apple.controlcenter" = {
          AutoHideMenuBarOption = 3; # 0 = always, 1 = desktop only, 2 = fullscreen only, 3 = never
        };

        NSGlobalDomain = {
          AppleMenuBarVisibleInFullscreen = true;
        };
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
      "208.68.182.68"
      "208.68.182.182"
      "1.1.1.1"
      "1.0.0.1"
    ];
  };
}
