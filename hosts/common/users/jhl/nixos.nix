{
  config,
  lib,
  inputs,
  outputs,
  ...
}:
#############################################################
#
#  User: jhl -- the NixOS half
#
#  Empty skeleton; no NixOS machine imports it yet. Kept structurally in step
#  with darwin.nix -- edit here when the first Linux machine arrives.
#
#############################################################
let
  user = config.hostSpec.username;
in {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    extraSpecialArgs = {
      inherit inputs outputs;
      isDarwin = false;
      hostSpec = config.hostSpec;
    };

    users.${user}.imports = [
      (lib.custom.relativeToRoot "home/${user}/${config.hostSpec.hostName}.nix")
    ];
  };
}
