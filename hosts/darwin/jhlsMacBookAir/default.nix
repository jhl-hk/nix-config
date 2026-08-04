{lib, ...}:
#############################################################
#
#  jhlsMacBookAir -- MacBook Air
#
#############################################################
{
  imports = map lib.custom.relativeToRoot [
    "hosts/common/optional/darwin/steam.nix"
  ];

  hostSpec = {
    hostName = "jhlsMacBookAir";
    isMobile = true;
  };

  # 这台机器原本设的是 assets/HNDT3.jpg，但那个文件不在仓库里
  # （assets/ 只有 bg.jpeg 和 idebg.jpg），所以一直是失败的。
  # 把图片加进 assets/ 之后，取消下面这行的注释即可。
  # darwinWallpaper = lib.custom.relativeToRoot "assets/HNDT3.jpg";
}
