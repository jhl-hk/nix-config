{inputs, ...}:
#############################################################
#
#  Overlays
#
#  五层，按顺序叠加：
#    additions          -- pkgs/common/ 下的自制包，自动发现
#    customLib          -- 把 lib.custom 挂进 pkgs.lib
#    modifications      -- 手写的 nixpkgs 包覆写，全平台
#    linuxModifications -- 只在 Linux 上生效的覆写
#    unstable-packages  -- 暴露 pkgs.unstable.<x>
#
#############################################################
{
  # pkgs/common/<name>/package.nix 丢进去就能用 pkgs.<name>，不需要改这里。
  additions = final: _prev:
    inputs.nixpkgs.lib.packagesFromDirectoryRecursive {
      inherit (final) callPackage;
      directory = ../pkgs/common;
    };

  # 让 lib.custom 在 home-manager 作用域里也能用。
  #
  # 不能走 extraSpecialArgs.lib —— 那会把 home-manager 自己的 lib 整个顶掉，
  # 于是 lib.hm 消失，HM 里任何用到 lib.hm.* 的模块（mako、大量 service）
  # 会以 "attribute 'hm' missing" 炸掉。
  #
  # 挂在 pkgs.lib 上就没这个问题：HM 的 lib 是 `pkgs.lib.extend hmExtension`，
  # 所以 custom 和 hm 会同时在。系统侧则走 flake.nix 的 specialArgs.lib。
  customLib = _final: prev: {
    lib =
      prev.lib
      // {
        custom = import ../lib {inherit (prev) lib;};
      };
  };

  # 全平台生效的 nixpkgs 包覆写。
  modifications = _final: _prev: {
    # 例：
    # foo = _prev.foo.overrideAttrs (old: { patches = old.patches ++ [ ./fix.patch ]; });
  };

  # 只在 Linux 上生效。用 optionalAttrs 而不是 mkIf —— 属性在 Darwin 上
  # 是「字面不存在」，比 mkIf 更严格，能挡住求值期的 unknown attribute。
  linuxModifications = _final: prev:
    prev.lib.optionalAttrs prev.stdenv.isLinux {
      # 例：
      # neovim = _final.unstable.neovim;
    };

  # 想要某个包的更新版本时，优先用 pkgs.unstable.<x>，别去 override。
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };
}
