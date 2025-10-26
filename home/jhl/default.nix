{ config, pkgs, ... }:

#############################################################
#
#  Home Manager Configuration for jhl
#  User-specific environment and dotfiles
#
#############################################################

{
  imports = [
    ./programs
    ./shell
  ];

  # Home Manager settings
  home = {
    username = "jhl";
    homeDirectory = "/Users/jhl";
    stateVersion = "24.05";

    # Disable version mismatch check (we're using unstable nixpkgs with stable darwin)
    enableNixpkgsReleaseCheck = false;

    # Environment variables
    sessionVariables = {
      EDITOR = "vim";
    };
  };

  system = {
    # Set desktop wallpaper on system activation
    activationScripts.postActivation.text = ''
      # Set wallpaper for all desktops and spaces (run as user)
      sudo -u jhl /usr/bin/osascript -e 'tell application "System Events" to tell every desktop to set picture to "/Users/jhl/Documents/nix-config/assets/HNDT3.jpg"'
    '';
  }

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
