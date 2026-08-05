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
}
