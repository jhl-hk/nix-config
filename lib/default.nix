{lib, ...}:
#############################################################
#
#  lib.custom
#
#  通过 flake.nix 里的 `nixpkgs.lib.extend` 挂到 `lib.custom`，
#  所以任何拿得到 `lib` 的模块都能直接用，不需要额外 import。
#
#############################################################
{
  # 把一个**字符串**片段解析成相对 flake 根目录的路径。
  #
  #   lib.custom.relativeToRoot "hosts/common/core"   -- 对
  #   lib.custom.relativeToRoot ./hosts/common/core   -- 错，lib.path.append 要字符串
  #
  # 用字符串而不是路径字面量，是为了让路径在 store 里保持稳定的标识。
  relativeToRoot = lib.path.append ../.;

  # 列出 `path` 下所有可以直接塞进 `imports` 的条目：子目录，
  # 以及除 `default.nix` 以外的 .nix 文件。
  #
  # 排除 default.nix 是关键 —— scanPaths 就是给 default.nix 自己调用的，
  # 不排除会无限递归。
  #
  # 效果：任何和「调用了 scanPaths 的 default.nix」并列的文件/目录都会被
  # 自动导入，不需要注册。modules/ 下面全靠这个。
  scanPaths = path:
    builtins.map (f: path + "/${f}") (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          name: type: (type == "directory") || ((name != "default.nix") && (lib.strings.hasSuffix ".nix" name))
        ) (builtins.readDir path)
      )
    );
}
