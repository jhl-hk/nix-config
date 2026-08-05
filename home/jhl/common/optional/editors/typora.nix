{pkgs, ...}:
#############################################################
#
#  Typora Configuration
#  Automatically installs themes from personal repo
#
#############################################################
let
  # Typora theme directory (macOS)
  typoraThemesDir = "Library/Application Support/abnerworks.Typora/themes";

  # Fetch the themes from the personal GitHub repo
  myTyporaThemes = pkgs.fetchFromGitHub {
    owner = "jhl-hk";
    repo = "typora-themes";
    rev = "86de879d2765a2ca09253b0edef677fb28271459"; # or pin a specific commit hash
    sha256 = "sha256-sIguntwaIv3y7TT1Bw8n6Ld67j8c2vjjuzKK68d6caA=";
  };
in {
  # Link everything in the theme repo into the Typora theme directory
  home.file."${typoraThemesDir}".source = myTyporaThemes;

  # Or, to link only specific theme files, name them individually:
  # home.file = {
  #   "${typoraThemesDir}/theme1.css".source = "${myTyporaThemes}/theme1.css";
  #   "${typoraThemesDir}/theme1".source = "${myTyporaThemes}/theme1";
  # };
}
