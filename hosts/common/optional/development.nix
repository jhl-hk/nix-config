{ pkgs, ... }:

#############################################################
#
#  Optional: Development Tools
#  Common development packages and tools
#
#############################################################

{
  environment.systemPackages = with pkgs; [
    # Version control
    git
    gh  # GitHub CLI

    # Build tools
    gnumake
    cmake

    # Languages
    python3
    nodejs
    go

    # Editors
    vim
    neovim

    # Tools
    jq
    ripgrep
    fd
    bat
    exa
    fzf
  ];
}
