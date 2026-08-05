{
  config,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  User: jhl -- the platform-agnostic half
#
#  The three-file split (default / darwin / nixos) is pure convention; Nix
#  does not pick by platform on its own. The platform half is imported
#  explicitly alongside this one by hosts/common/core/default.nix.
#
#############################################################
let
  user = config.hostSpec.username;
in {
  users.users.${user} =
    {
      shell = pkgs.zsh;
    }
    # Darwin's users.users.<u> has no group / extraGroups / uid attributes;
    # without this gate the Darwin side fails with an unknown-option error.
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      isNormalUser = true;
      group = "wheel";
      extraGroups = ["wheel"];
    };
}
