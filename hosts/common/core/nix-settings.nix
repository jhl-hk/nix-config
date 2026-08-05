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

  # Applies the layers from overlays/default.nix. home-manager runs with
  # useGlobalPkgs, so adding them here means the home side gets the same pkgs.
  nixpkgs.overlays = builtins.attrValues outputs.overlays;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Garbage collection
  nix.gc = {
    automatic = lib.mkDefault true;
    options = lib.mkDefault "--delete-older-than 7d";
  };
}
