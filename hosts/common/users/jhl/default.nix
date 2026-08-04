{
  config,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  User: jhl -- 平台无关的那半
#
#  三文件拆分（default / darwin / nixos）纯粹是约定，Nix 不会自己
#  按平台挑。平台那半由 hosts/common/core/default.nix 显式一起导入。
#
#############################################################
let
  user = config.hostSpec.username;
in {
  users.users.${user} =
    {
      shell = pkgs.zsh;
    }
    # Darwin 的 users.users.<u> 没有 group / extraGroups / uid 这些属性，
    # 不 gate 的话 Darwin 侧求值会报 unknown option。
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      isNormalUser = true;
      group = "wheel";
      extraGroups = ["wheel"];
    };
}
