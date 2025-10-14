{ lib, pkgs, ... }:

#############################################################
#
#  Common Core Configuration
#  Shared across all hosts (Darwin & NixOS)
#
#############################################################

{
  imports = [
    ./nix-settings.nix
  ];

  # Core packages available on all systems
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];
}
