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
        orientation = "right";
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
      # and it covers just 7 of these keys, so it cannot express the 8 / 2 this
      # machine actually uses. Hence the raw values here. Module state lives in
      # the ByHost plist, at the same path nix-darwin itself uses when writing
      # controlcenter.
      CustomUserPreferences = {
        # Captured from jhlsMacBookPro on 2026-09-11. The menu bar is kept
        # almost empty on purpose: the modules live in Control Center and only
        # Screen Mirroring is allowed to surface while it is active.
        "~${config.system.primaryUser}/Library/Preferences/ByHost/com.apple.controlcenter" = {
          Bluetooth = 8;
          Display = 8;
          FocusModes = 8;
          NowPlaying = 8;
          ScreenMirroring = 2;
          Sound = 8;
          Spotlight = 8;
          Timer = 8;
          VoiceControl = 8;
          WiFi = 8;
          UserSwitcher = 24;
          ShowSuggestions = 1; # Control Center > Show Suggestions
        };

        # These keys do not live in the ByHost domain
        "com.apple.controlcenter" = {
          AutoHideMenuBarOption = 3; # 0 = always, 1 = desktop only, 2 = fullscreen only, 3 = never
        };

        # Input-source menu (the flag / ABC indicator)
        "com.apple.TextInputMenu".visible = true;

        # Siri stays out of the menu bar
        "com.apple.Siri".StatusMenuVisible = false;

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
