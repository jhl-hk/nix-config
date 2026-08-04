{lib, ...}:
# 自动导入同级的所有 .nix 文件和子目录（default.nix 自身除外）。
# 往这个目录里丢文件即生效，不需要在任何地方注册。
{
  imports = lib.custom.scanPaths ./.;
}
