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

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
