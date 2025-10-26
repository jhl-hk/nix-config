{ config, pkgs, ... }:

#############################################################
#
#  Home Manager Configuration for valor
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
    username = "valor";
    homeDirectory = "/Users/valor";
    stateVersion = "24.05";

    # Disable version mismatch check (we're using unstable nixpkgs with stable darwin)
    enableNixpkgsReleaseCheck = false;

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
    userName = "Valor";
    userEmail = "valor@example.com";
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
