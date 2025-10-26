{ pkgs, ... }:

#############################################################
#
#  User: valor
#  System-level user configuration
#
#############################################################

{
  users.users.valor = {
    home = "/Users/valor";
    description = "Valor";
    shell = pkgs.zsh;
  };

  # Set as primary user on Darwin
  system.primaryUser = "valor";

  # Trust this user for Nix operations
  nix.settings.trusted-users = [ "valor" ];
}
