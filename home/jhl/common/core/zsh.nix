{
  lib,
  hostSpec,
  ...
}:
#############################################################
#
#  Zsh
#
#  Strictly speaking the Homebrew / JAVA_HOME PATH lines only hold on macOS,
#  but there are only Macs right now so they stay here for the moment. Move
#  them to ./darwin.nix when the first Linux machine arrives.
#
#  initContent is an mkMerge because the completion block has to be ordered.
#  home-manager's zsh module lays .zshrc out by mkOrder, and the parts that
#  matter here are:
#
#    570  completionInit (the compinit call below)
#    650  our completion zstyles -- compsys must exist before they are set,
#         and menu selection must be configured before anything binds Tab
#    700  autosuggestion
#    851  zoxide (./zoxide.nix)
#   1000  a bare string, i.e. the PATH block at the bottom of this file
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

    initContent = lib.mkMerge [
      # Completion behaviour, adopted from
      # https://github.com/ChanningHe/nix-config. Order 650: after compinit
      # (570), before autosuggestions (700).
      (lib.mkOrder 650 ''
        # CLICOLOR is what macOS's BSD ls reads. LS_COLORS is the GNU format
        # and is set here for one reason only: the list-colors zstyle at the
        # bottom of this block parses it to colourise the completion menu.
        # BSD ls ignores it, so the two do not fight.
        export CLICOLOR=1
        export LS_COLORS="di=1;36:ln=1;35:so=32:pi=33:ex=1;32:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"

        zstyle ':completion:*' completer _expand _complete _ignored

        # Two matchers, tried in order: first case-insensitive, then
        # partial-word on . _ and - separators -- so `ho.ni<Tab>` finds
        # `home/jhl/common/core/zsh.nix` and `SOPS_A<Tab>` finds SOPS_AGE_*.
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'

        # Tab opens an interactive menu; arrows and further Tabs move through
        # it. Loads zsh/complist on demand.
        zstyle ':completion:*' menu select
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      '')

      ''
        # Add Homebrew to PATH
        export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

        # Add Home Manager binaries to PATH
        export PATH="/etc/profiles/per-user/$USER/bin:$PATH"

        # Java (OpenJDK via Homebrew)
        export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
        export JAVA_HOME="/opt/homebrew/opt/openjdk"

        # Needed when driving sops by hand
        export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
      ''
    ];
  };
}
