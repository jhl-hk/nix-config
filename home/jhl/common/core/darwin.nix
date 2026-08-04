{...}:
#############################################################
#
#  Home Core -- macOS 那半
#  由 common/core/default.nix 的 ./${platform}.nix 挑中。
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
