{config, ...}:
#############################################################
#
#  NixOS Core
#
#  空骨架。现在一台 NixOS 机器都没有，这个文件不会被求值
#  （hosts/common/core/default.nix 按 isDarwin 挑平台）。
#
#  加第一台 NixOS 机器时，跨平台的东西放 core/default.nix，
#  只有 Linux 才有的放这里。
#
#############################################################
{
  networking.hostName = config.hostSpec.hostName;

  # NixOS 要**字符串**，Darwin 要整数。
  system.stateVersion = "25.05";
}
