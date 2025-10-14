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

    # User-specific packages
    packages = with pkgs; [
      # Add user-specific packages here
    ];

    # Environment variables
    sessionVariables = {
      EDITOR = "vim";
    };
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
