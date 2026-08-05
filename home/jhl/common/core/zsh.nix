{hostSpec, ...}:
#############################################################
#
#  Zsh
#
#  Strictly speaking the Homebrew / JAVA_HOME PATH lines only hold on macOS,
#  but there are only Macs right now so they stay here for the moment. Move
#  them to ./darwin.nix when the first Linux machine arrives.
#
#############################################################
let
  # Repo path. This used to be hard-coded as ~/Documents/nix-config, which
  # broke all three aliases once the repo moved under nix-src/.
  flakeDir = "${hostSpec.home}/Documents/nix-src/nix-config";
in {
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
      sysnew = "cd ${flakeDir} && just rebuild && cd -";
      sysup = "cd ${flakeDir} && just update && cd -";
      syscl = "cd ${flakeDir} && just clean && cd -";
    };

    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
    };

    initContent = ''
      # Add Homebrew to PATH
      export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

      # Add Home Manager binaries to PATH
      export PATH="/etc/profiles/per-user/$USER/bin:$PATH"

      # Java (OpenJDK via Homebrew)
      export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
      export JAVA_HOME="/opt/homebrew/opt/openjdk"

      # Needed when driving sops by hand
      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    '';
  };
}
