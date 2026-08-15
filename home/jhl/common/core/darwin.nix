{...}:
#############################################################
#
#  Home Core -- the macOS half
#  Selected by ./${platform}.nix in common/core/default.nix.
#
#############################################################
{
  imports = [
    ./darwin/keyboard.nix
    ./darwin/stats.nix
    ./darwin/ssh-agent.nix
  ];

  home.sessionPath = ["/opt/homebrew/bin"];

  # PATH lines that used to sit in ../zsh.nix. They moved here when the first
  # Linux machine arrived: none of these paths exist off macOS, and
  # /etc/profiles/per-user/$USER is where nix-darwin's home-manager module puts
  # the user profile -- standalone home-manager uses ~/.nix-profile instead and
  # exports it itself.
  #
  # A bare string, so it keeps mkOrder 1000 and stays at the bottom of .zshrc,
  # exactly where it was before the move. See the ordering table in ../zsh.nix.
  programs.zsh.initContent = ''
    # Add Homebrew to PATH
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

    # Add Home Manager binaries to PATH
    export PATH="/etc/profiles/per-user/$USER/bin:$PATH"

    # Java (OpenJDK via Homebrew)
    export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
    export JAVA_HOME="/opt/homebrew/opt/openjdk"
  '';
}
