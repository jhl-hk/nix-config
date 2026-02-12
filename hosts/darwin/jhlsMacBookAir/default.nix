{ pkgs, ... }:

#############################################################
#
#  MacBook Air - jhlsMacBookAir
#  macOS Darwin Configuration
#
#############################################################

{
  imports = [
    # Host-specific configurations
  ];

  # Host identification
  networking.hostName = "jhlsMacBookAir";
  networking.computerName = "jhlsMacBookAir";
  system.defaults.smb.NetBIOSName = "jhlsMacBookAir";

# 系统激活脚本设置壁纸
  system.activationScripts.postActivation.text = ''
    # Set wallpaper for user jhl
    sudo -u jhl /usr/bin/osascript -e 'tell application "System Events" to tell every desktop to set picture to "/Users/jhl/Documents/nix-config/assets/HNDT3.jpg"' || true
  '';
}
