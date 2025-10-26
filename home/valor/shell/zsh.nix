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

    # Skip insecure directory check for Nix store paths
    completionInit = ''
      autoload -U compinit && compinit -u
    '';

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

    initExtra = ''
      # Add Homebrew to PATH (Intel Mac uses /usr/local, Apple Silicon uses /opt/homebrew)
      if [[ $(uname -m) == "x86_64" ]]; then
        export HOMEBREW_PREFIX="/usr/local"
      else
        export HOMEBREW_PREFIX="/opt/homebrew"
      fi
      export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"

      # Add Home Manager binaries to PATH
      export PATH="/etc/profiles/per-user/$USER/bin:$PATH"

      # Java (OpenJDK via Homebrew)
      export PATH="$HOMEBREW_PREFIX/opt/openjdk/bin:$PATH"
      export JAVA_HOME="$HOMEBREW_PREFIX/opt/openjdk"

      # Additional zsh configuration
    '';
  };
}
