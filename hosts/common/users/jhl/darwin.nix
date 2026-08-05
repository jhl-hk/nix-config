{
  config,
  lib,
  inputs,
  outputs,
  ...
}:
#############################################################
#
#  User: jhl -- the macOS half
#
#  home-manager is wired up here rather than in flake.nix, because working out
#  which home file to import requires reading config.hostSpec, and config is
#  not available at the flake.nix layer.
#
#############################################################
let
  user = config.hostSpec.username;
in {
  users.users.${user} = {
    home = config.hostSpec.home;
    description = config.hostSpec.userFullName;
  };

  system.primaryUser = user;
  nix.settings.trusted-users = [user];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    # Note there is **no** lib here. home-manager's own lib is
    # pkgs.lib.extend hmExtension; passing lib via extraSpecialArgs replaces it
    # wholesale and lib.hm disappears. lib.custom reaches the HM side through
    # the customLib layer in overlays, which attaches it to pkgs.lib.
    extraSpecialArgs = {
      inherit inputs outputs;
      isDarwin = true;
      hostSpec = config.hostSpec;
    };

    users.${user}.imports = [
      (lib.custom.relativeToRoot "home/${user}/${config.hostSpec.hostName}.nix")
    ];
  };
}
