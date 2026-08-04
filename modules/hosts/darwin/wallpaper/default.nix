{
  config,
  lib,
  ...
}:
#############################################################
#
#  桌面壁纸
#
#  原来 system-defaults.nix 和 jhlsMacBookAir/default.nix 各写了一段
#  system.activationScripts.postActivation.text 去设壁纸。那个选项是
#  文本拼接，两段都会跑，最后哪个生效取决于顺序 —— 而且两处引用的
#  路径都指向已经不存在的 ~/Documents/nix-config/assets/。
#
#  改成一个选项之后只有一处定义，覆盖就是普通的赋值。
#  路径用 nix 路径而不是字符串，图片会被复制进 store，
#  不再依赖用户目录的布局。
#
#############################################################
let
  cfg = config.darwinWallpaper;
in {
  options.darwinWallpaper = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    example = lib.literalExpression ''lib.custom.relativeToRoot "assets/bg.jpeg"'';
    description = "所有桌面和 Space 的壁纸。null 表示不管壁纸。";
  };

  config = lib.mkIf (cfg != null) {
    system.activationScripts.postActivation.text = ''
      # 设置壁纸。osascript 要以登录用户身份跑，activation 是 root。
      sudo -u ${config.hostSpec.username} /usr/bin/osascript -e \
        'tell application "System Events" to tell every desktop to set picture to "${cfg}"' || true
    '';
  };
}
