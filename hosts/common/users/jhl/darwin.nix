{
  config,
  lib,
  inputs,
  outputs,
  ...
}:
#############################################################
#
#  User: jhl -- macOS 那半
#
#  home-manager 的接线在这里，不在 flake.nix。因为要读 config.hostSpec
#  才能算出该导入哪个 home 文件，而 flake.nix 那层还拿不到 config。
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

    # 注意这里**没有** lib。home-manager 自己的 lib 是
    # pkgs.lib.extend hmExtension，用 extraSpecialArgs 传 lib 会把它整个
    # 顶掉，于是 lib.hm 消失。lib.custom 由 overlays 的 customLib 层
    # 挂进 pkgs.lib，HM 侧照样能用。
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
