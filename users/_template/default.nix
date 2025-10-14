{ pkgs, ... }:

#############################################################
#
#  User: USERNAME
#  System-level user configuration
#
#############################################################

{
  users.users.USERNAME = {
    home = "/Users/USERNAME";  # Change to /home/USERNAME on Linux
    description = "FULL_NAME";
    shell = pkgs.zsh;

    # NixOS-specific (uncomment on NixOS):
    # isNormalUser = true;
    # extraGroups = [ "wheel" "networkmanager" ];
  };

  # Darwin-specific (comment out on NixOS)
  system.primaryUser = "USERNAME";

  # Trust this user for Nix operations
  nix.settings.trusted-users = [ "USERNAME" ];
}
