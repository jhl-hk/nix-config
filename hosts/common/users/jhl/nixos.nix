{
  config,
  lib,
  inputs,
  outputs,
  ...
}:
#############################################################
#
#  User: jhl -- NixOS 那半
#
#  空骨架，现在没有 NixOS 机器会导入它。
#  结构和 darwin.nix 保持一致，加第一台 Linux 机器时改这里。
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
