{ pkgs, lib, ... }:

let
  pname = "flclash";
  version = "0.8.92";
  sha256 = "17s66g9gmyf2mg5ym4vn81waprhlljchjriz683iass9gf96dxxj";

in
{
  home.packages = lib.mkIf (pkgs.stdenv.isDarwin && pkgs.stdenv.system == "aarch64-darwin") [
    (pkgs.stdenv.mkDerivation {
      inherit pname version;
      src = pkgs.fetchurl {
        url = "https://github.com/chen08209/FlClash/releases/download/v${version}/FlClash-${version}-macos-arm64.dmg";
        inherit sha256;
      };
      nativeBuildInputs = [ pkgs.hfsplus-tools ];
      installPhase = ''
        hdiutil attach $src -mountpoint ./flclash-dmg
        mkdir -p $out/Applications
        cp -r ./flclash-dmg/FlClash.app $out/Applications/
        hdiutil detach ./flclash-dmg
      '';
      meta = with lib; {
        description = "A Clash GUI that works on multiple platforms.";
        homepage = "https://github.com/chen08209/FlClash";
        license = licenses.gpl3;
        platforms = platforms.darwin;
      };
    })
  ];
}
