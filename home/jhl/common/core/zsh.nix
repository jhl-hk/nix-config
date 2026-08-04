{hostSpec, ...}:
#############################################################
#
#  Zsh
#
#  Homebrew / JAVA_HOME 那几行 PATH 严格来说只在 macOS 成立，
#  但现在只有 Mac 机器，先留在这里。加第一台 Linux 机器时
#  把它们挪到 ./darwin.nix。
#
#############################################################
let
  # 仓库路径。原来这里硬编码的是 ~/Documents/nix-config，
  # 仓库搬到 nix-src/ 之后三个别名全失效了。
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
      ll = "ls -lah";
      la = "ls -A";
      sysnew = "cd ${flakeDir} && just rebuild";
      sysup = "cd ${flakeDir} && just update";
      syscl = "cd ${flakeDir} && just clean";
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

      # sops 手工操作时用得到
      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    '';
  };
}
