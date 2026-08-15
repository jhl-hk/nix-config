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

  # GNU coreutils takes --color; BSD's does not, which is why this cannot go in
  # the cross-platform half. The Macs get colour from CLICOLOR=1 instead, set
  # in ./zsh.nix next to the LS_COLORS the completion menu parses.
  #
  # These two were in the hand-written ~/.bashrc that ./bash.nix replaces on
  # jhlsArchLinux. Declared here so the replacement is not a downgrade.
  home.shellAliases = {
    ls = "ls --color=auto";
    grep = "grep --color=auto";
  };

  # One agent per login, as a systemd user service.
  #
  # This replaces an `eval "$(ssh-agent)"` that the hand-written ~/.bashrc ran
  # on every interactive shell -- which starts a *new* agent each time. Three
  # were running on this machine when the line was found, each with its own
  # socket under ~/.ssh/agent/ and its own copy of whatever had been added to
  # it, so `ssh-add -l` answered differently depending on which terminal you
  # asked from.
  #
  # home-manager routes SSH_AUTH_SOCK through misc/ssh-auth-sock.nix rather
  # than home.sessionVariables, and the distinction is load-bearing here:
  # programs.ssh sets ForwardAgent = true (./ssh.nix), and that module only
  # overrides SSH_AUTH_SOCK when SSH_CONNECTION is unset. Set unconditionally
  # it would shadow a forwarded agent on every inbound ssh. Both bash
  # (profileExtra) and zsh (envExtra) get it.
  services.ssh-agent.enable = true;

  fonts.fontconfig.enable = true;

  # Han unification: pick the right orthography per language.
  #
  # noto-fonts-cjk is one family with five orthographies -- SC, TC, HK, JP, KR --
  # and fontconfig was resolving *everything* to the Korean one:
  #
  #   fc-match :lang=zh-cn  ->  Noto Sans CJK KR
  #   fc-match :lang=ja     ->  Noto Sans CJK KR
  #
  # The codepoints are shared, so nothing looks broken; the strokes are just
  # wrong. 直 骨 关 每 are drawn the Korean way in Chinese text and the Chinese
  # way in Japanese text. A native reader sees it immediately, and there is no
  # error anywhere to lead you to it -- which is exactly why it is pinned here
  # rather than left to whatever order fontconfig happens to scan in.
  #
  # This is the one CJK concern nix can own outright: fontconfig snippets are
  # generated, never written back by a tool, unlike ~/.config/fcitx5/profile
  # (see ../optional/desktop/fcitx5.nix).
  #
  # Numbered 60- so it lands after home-manager's own 10-hm-fonts.conf and
  # 52-hm-default-fonts.conf, which fonts.fontconfig.enable above writes.
  #
  # sans/serif prepend, monospace appends. Prepending a CJK font onto monospace
  # would hand it the Latin glyphs too, in mixed text where the surrounding
  # code should stay in the coding font; appending still wins for Chinese and
  # Japanese, because the Latin monospace fonts do not cover those languages at
  # all and lose on coverage before order is even considered. Verified with
  # fc-match for all six language/generic pairs.
  xdg.configFile."fontconfig/conf.d/60-cjk-orthography.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <match target="pattern">
        <test name="lang" compare="contains"><string>zh-cn</string></test>
        <test name="family"><string>sans-serif</string></test>
        <edit name="family" mode="prepend" binding="strong"><string>Noto Sans CJK SC</string></edit>
      </match>
      <match target="pattern">
        <test name="lang" compare="contains"><string>zh-cn</string></test>
        <test name="family"><string>serif</string></test>
        <edit name="family" mode="prepend" binding="strong"><string>Noto Serif CJK SC</string></edit>
      </match>
      <match target="pattern">
        <test name="lang" compare="contains"><string>zh-cn</string></test>
        <test name="family"><string>monospace</string></test>
        <edit name="family" mode="append" binding="strong"><string>Noto Sans Mono CJK SC</string></edit>
      </match>

      <match target="pattern">
        <test name="lang" compare="contains"><string>ja</string></test>
        <test name="family"><string>sans-serif</string></test>
        <edit name="family" mode="prepend" binding="strong"><string>Noto Sans CJK JP</string></edit>
      </match>
      <match target="pattern">
        <test name="lang" compare="contains"><string>ja</string></test>
        <test name="family"><string>serif</string></test>
        <edit name="family" mode="prepend" binding="strong"><string>Noto Serif CJK JP</string></edit>
      </match>
      <match target="pattern">
        <test name="lang" compare="contains"><string>ja</string></test>
        <test name="family"><string>monospace</string></test>
        <edit name="family" mode="append" binding="strong"><string>Noto Sans Mono CJK JP</string></edit>
      </match>
    </fontconfig>
  '';
}
