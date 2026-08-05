{config, ...}:
#############################################################
#
#  NixOS Core
#
#  Empty skeleton. There are no NixOS machines yet, so this file is never
#  evaluated (hosts/common/core/default.nix picks the platform by isDarwin).
#
#  When the first NixOS machine arrives, cross-platform things go in
#  core/default.nix and Linux-only things go here.
#
#############################################################
{
  networking.hostName = config.hostSpec.hostName;

  # NixOS wants a **string**; Darwin wants an integer.
  system.stateVersion = "25.05";
}
