{...}:
#############################################################
#
#  fcitx5 -- Simplified Chinese (Pinyin) and Japanese (Mozc) input
#
#  Three input methods in one group, and the point of the whole file is the
#  per-method keyboard layout:
#
#    keyboard-us-colemak   English, this machine's actual layout
#    pinyin                Simplified Chinese, forced to us  (QWERTY)
#    mozc                  Japanese romaji,    forced to us  (QWERTY)
#
#  Pinyin and romaji are both spelled out in Latin letters, and the muscle
#  memory for both is QWERTY -- typing "zhong" or "nihon" on Colemak lands on
#  entirely different keys. fcitx5 applies the per-item Layout while that input
#  method is active and restores the group layout when you switch back, so
#  English stays Colemak without a second thought.
#
#  -- The binaries are pacman's, deliberately -------------------------------
#
#    sudo pacman -S --needed fcitx5-im fcitx5-chinese-addons fcitx5-mozc
#
#  fcitx5 is not installable from nix here. fcitx5-gtk and fcitx5-qt are IM
#  modules that get dlopen'd *into other applications*; built against nixpkgs'
#  Qt and GTK they would never load into Arch's Zed, Ghostty or Plasma, and
#  input would silently do nothing in every GUI app. Same class of problem as
#  the NVIDIA GL stack. So this file manages configuration only -- exactly the
#  split ../editors/zed.nix already runs with package = null.
#
#  The input method identifiers below are the .conf basenames those packages
#  install under share/fcitx5/inputmethod/: `pinyin` from fcitx5-chinese-addons
#  (LangCode zh_CN) and `mozc` from fcitx5-mozc (LangCode ja). They are not
#  free-form names -- a typo means fcitx5 quietly drops the entry.
#
#  -- What managing profile costs -------------------------------------------
#
#  This is a read-only symlink into the store, and fcitx5-configtool writes
#  this file back every time you add, remove or reorder an input method. Once
#  managed here, **the GUI can no longer save those changes** -- it will appear
#  to work and then not persist. Add input methods by editing this file and
#  rebuilding.
#
#  That is the trade README's "read-only store symlink" trap describes, taken
#  knowingly: the set of input methods and their layouts is the thing worth
#  pinning across machines, and it is not something that changes weekly.
#
#  ~/.config/fcitx5/config -- hotkeys, candidate window, theme -- is left
#  **unmanaged** on purpose. Those are preferences you tune by trying them, the
#  GUI is the right tool, and nothing about them needs to be reproducible.
#
#  -- Plasma still needs one thing this file cannot do ----------------------
#
#  On Wayland, KWin has to be told to launch fcitx5 as the input method:
#
#    kwriteconfig6 --file kwinrc --group Wayland \
#      --key InputMethod --type path /usr/share/applications/fcitx5-wayland-launcher.desktop
#
#  That lives in kwinrc, which System Settings rewrites constantly -- managing
#  it from nix would freeze every unrelated KWin setting too. One-time command,
#  then log out and back in.
#
#############################################################
{
  xdg.configFile."fcitx5/profile".text = ''
    [Groups/0]
    Name=Default
    Default Layout=us-colemak
    DefaultIM=keyboard-us-colemak

    [Groups/0/Items/0]
    Name=keyboard-us-colemak
    Layout=

    [Groups/0/Items/1]
    Name=pinyin
    Layout=us

    [Groups/0/Items/2]
    Name=mozc
    Layout=us

    [GroupOrder]
    0=Default
  '';
}
