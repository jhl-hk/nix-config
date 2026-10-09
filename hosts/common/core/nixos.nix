{
  config,
  pkgs,
  ...
}:
#############################################################
#
#  NixOS Core
#
#  Linux-only system baseline. Cross-platform things go in core/default.nix.
#
#############################################################
{
  networking.hostName = config.hostSpec.hostName;

  # users.users.<u>.shell = pkgs.zsh (users/jhl/default.nix) is rejected by
  # NixOS unless zsh is enabled system-wide.
  programs.zsh.enable = true;

  # `xterm-ghostty` terminfo, so sshing in from Ghostty works.
  environment.systemPackages = [pkgs.ghostty.terminfo];

  # NixOS wants a **string**; Darwin wants an integer.
  system.stateVersion = "26.05";
}
