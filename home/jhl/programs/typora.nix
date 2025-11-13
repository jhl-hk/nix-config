{ config, pkgs, ... }:

#############################################################
#
#  Typora Configuration
#  Automatically installs themes from personal repo
#
#############################################################

let
  # Typora 主题目录（macOS）
  typoraThemesDir = "Library/Application Support/abnerworks.Typora/themes";

  # 从你的 GitHub 仓库获取主题
  myTyporaThemes = pkgs.fetchFromGitHub {
    owner = "jhl-hk";
    repo = "typora-themes";
    rev = "main";  # 或者使用特定的 commit hash
    sha256 = "sha256-xSIRNE2UKx6rd/GUopIbaB0HNj4GS4XpM/mYR6yK6lc=";
  };
in
{
  # 将主题仓库中的所有内容链接到 Typora 主题目录
  home.file."${typoraThemesDir}".source = myTyporaThemes;

  # 或者如果你只想链接特定的主题文件，可以单独指定：
  # home.file = {
  #   "${typoraThemesDir}/theme1.css".source = "${myTyporaThemes}/theme1.css";
  #   "${typoraThemesDir}/theme1".source = "${myTyporaThemes}/theme1";
  # };
}
