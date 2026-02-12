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
    stateVersion = "25.11";

    # Disable version mismatch check (we're using unstable nixpkgs with stable darwin)
    enableNixpkgsReleaseCheck = false;

    # Environment variables
    sessionVariables = {
      EDITOR = "vim";
    };
  };

  users.users.jhl = {
    home = "/Users/jhl";
    description = "JHL";
    shell = pkgs.zsh;
  };

  # Set as primary user on Darwin
  system.primaryUser = "jhl";

  # Trust this user for Nix operations
  nix.settings.trusted-users = [ "jhl" ];

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
