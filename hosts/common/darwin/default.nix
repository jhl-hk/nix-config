{ pkgs, ... }:

#############################################################
#
#  Common Darwin Configuration
#  Shared across all macOS hosts
#
#############################################################

{
  imports = [
    ./system-defaults.nix
    ./homebrew.nix
  ];

  # System state version
  system.stateVersion = 6;

  # Nix store optimization (use this instead of auto-optimise-store on Darwin)
  nix.optimise.automatic = true;

  # Add ability to use TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  # Create /etc/zshrc that loads the nix-darwin environment
  programs.zsh = {
    enable = true;
    # Initialize Starship prompt
    promptInit = ''
      eval "$(${pkgs.starship}/bin/starship init zsh)"
    '';
  };

  # Add Homebrew paths to system PATH
  environment.systemPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/opt/homebrew/opt/openssh/bin"
  ];

  # Common Darwin packages
  environment.systemPackages = with pkgs; [
    starship  # Modern shell prompt
  ];
}
