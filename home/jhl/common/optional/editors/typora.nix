{pkgs, ...}:
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
    rev = "86de879d2765a2ca09253b0edef677fb28271459"; # 或者使用特定的 commit hash
    sha256 = "sha256-sIguntwaIv3y7TT1Bw8n6Ld67j8c2vjjuzKK68d6caA=";
  };
in {
  # 将主题仓库中的所有内容链接到 Typora 主题目录
  home.file."${typoraThemesDir}".source = myTyporaThemes;

  # 或者如果你只想链接特定的主题文件，可以单独指定：
  # home.file = {
  #   "${typoraThemesDir}/theme1.css".source = "${myTyporaThemes}/theme1.css";
  #   "${typoraThemesDir}/theme1".source = "${myTyporaThemes}/theme1";
  # };
}
