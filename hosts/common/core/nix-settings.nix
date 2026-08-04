{
  lib,
  outputs,
  ...
}:
#############################################################
#
#  Nix Core Settings
#  Common Nix configuration for all hosts
#
#############################################################
{
  # Enable flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # 应用 overlays/default.nix 里的四层。home-manager 用了 useGlobalPkgs，
  # 所以这里加上之后 home 侧拿到的也是同一个 pkgs。
  nixpkgs.overlays = builtins.attrValues outputs.overlays;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Garbage collection
  nix.gc = {
    automatic = lib.mkDefault true;
    options = lib.mkDefault "--delete-older-than 7d";
  };
}
