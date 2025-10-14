{ config, pkgs, ... }:

#############################################################
#
#  Home Manager Configuration for USERNAME
#  User-specific environment and dotfiles
#
#############################################################

{
  imports = [
    # Import program and shell configurations
    # ./programs
    # ./shell

    # Import optional modules as needed:
    # ../common/optional/vscode.nix
  ];

  # Home Manager settings
  home = {
    username = "USERNAME";
    homeDirectory = "/Users/USERNAME";  # Change to /home/USERNAME on Linux
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

  # Git configuration
  programs.git = {
    enable = true;
    userName = "FULL_NAME";
    userEmail = "EMAIL@example.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -lah";
    };
  };
}
