{ config, ... }:

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

    # Set desktop wallpaper on system activation
    activationScripts.postActivation.text = ''
      # Set wallpaper for all desktops and spaces (run as user)
      sudo -u jhl /usr/bin/osascript -e 'tell application "System Events" to tell every desktop to set picture to "/Users/jhl/Documents/nix-config/assets/bg.jpeg"'
    '';

    defaults = {
      # Menu bar clock
      menuExtraClock = {
        Show24Hour = true;    # 24 小时制
        ShowAMPM = true;      # 只在 12 小时制下生效，保留当前值
        ShowDayOfWeek = true; # 显示星期
        ShowDate = 0;         # 0 = 空间允许时显示日期, 1 = 总是, 2 = 从不
      };

      # Control Center / 菜单栏图标
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
        Clicking = true;  # Enable tap to click
        TrackpadRightClick = true;
      };

      # NSGlobalDomain settings
      NSGlobalDomain = {
        AppleICUForce24HourTime = true;
        AppleInterfaceStyle = "Dark";  # Dark mode
        _HIHideMenuBar = false;  # 不自动隐藏菜单栏
        # 键盘相关的键在 home/programs/keyboard.nix
      };

      # 菜单栏里其余的开关，nix-darwin 没有对应的 typed option。
      #
      # com.apple.controlcenter 的每个模块是个位域，不是布尔：
      #   2  = 活动时显示 (show when active)
      #   8  = 不在菜单栏显示
      #   18 = 始终在菜单栏显示   (= 16 | 2)
      #   24 = 明确设为不显示     (= 16 | 8)
      # nix-darwin 的 system.defaults.controlcenter.* 只会写 18/24，
      # 用它会把 Sound/Display/NowPlaying 从"活动时显示"变成"常驻菜单栏"，
      # 所以这里直接写原始值。模块状态存在 ByHost plist 里，
      # 路径跟 nix-darwin 自己写 controlcenter 用的是同一个。
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

        # 这个键不在 ByHost 域里
        "com.apple.controlcenter" = {
          AutoHideMenuBarOption = 3;  # 0 = 总是隐藏, 1 = 仅桌面, 2 = 仅全屏, 3 = 从不
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
