{ pkgs, ... }:

#############################################################
#
#  User: jhl
#  System-level user configuration
#
#############################################################

{
  users.users.jhl = {
    home = "/Users/jhl";
    description = "JHL";
    shell = pkgs.zsh;
  };

  # Set as primary user on Darwin
  system.primaryUser = "jhl";

  # Trust this user for Nix operations
  nix.settings.trusted-users = [ "jhl" ];
}
