{pkgs, ...}:
#############################################################
#
#  Home Core -- the Linux half
#  Selected by ./${platform}.nix in common/core/default.nix.
#
#  "linux", not "nixos": this is picked for every machine where
#  hostSpec.isDarwin is false, which now includes jhlsArchLinux -- nix running
#  on top of Arch, with no NixOS anywhere. Anything genuinely NixOS-only would
#  belong in the system lane (hosts/common/core/nixos.nix), not here.
#
#  Do not rename it. common/core/default.nix interpolates the filename from
#  hostSpec.isDarwin, so a mismatched name fails silently.
#
#  -- Fonts ---------------------------------------------------------------
#
#  The rest of core assumes Maple Mono is installed and picks glyphs on that
#  basis: ./starship.nix documents which symbols it chose because Maple Mono
#  ships them, and ../optional/editors/zed.nix sets buffer_font_family to it.
#  On the Macs that assumption is met by the font-maple-mono cask in
#  hosts/common/core/darwin/apps.nix. There is no cask here, so the same font
#  comes from nixpkgs instead.
#
#  maple-mono.variable, not one of the ~40 other attributes in that set,
#  because the cask installs Maple Mono *Variable* and the two machines should
#  render identically. Verified to register the family name "Maple Mono", which
#  is what both consumers ask for by name -- an NF or CN build would install
#  fine and then not match.
#
#  fontconfig has to be told about it. Nothing outside nix scans
#  ~/.nix-profile/share/fonts on a distro that owns /etc/fonts, so without
#  this the font is on disk and still invisible -- Zed falls back silently and
#  starship prints tofu. home-manager writes
#  ~/.config/fontconfig/conf.d/10-hm-fonts.conf to close that gap.
#
#############################################################
{
  home.packages = [pkgs.maple-mono.variable];

  fonts.fontconfig.enable = true;
}
