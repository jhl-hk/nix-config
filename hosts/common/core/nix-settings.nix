{ lib, ... }:

#############################################################
#
#  Nix Core Settings
#  Common Nix configuration for all hosts
#
#############################################################

{
  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Garbage collection
  nix.gc = {
    automatic = lib.mkDefault true;
    options = lib.mkDefault "--delete-older-than 7d";
  };
}
