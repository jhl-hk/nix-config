{ ... }:

#############################################################
#
#  Zsh Configuration
#
#############################################################

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -lah";
      la = "ls -A";
      # Nix-specific aliases
      rebuild = "darwin-rebuild switch --flake ~/.config/nix-config";
      update = "nix flake update ~/.config/nix-config";
    };

    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
    };

    initContent = ''
      # Add Home Manager binaries to PATH
      export PATH="/etc/profiles/per-user/$USER/bin:$PATH"

      # Additional zsh configuration
    '';
  };
}
