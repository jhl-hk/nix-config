{...}:
#############################################################
#
#  fcitx5 -- Simplified Chinese (Pinyin) input
#
#  Two input methods in one group, and the point of the whole file is the
#  per-method keyboard layout:
#
#    keyboard-us-colemak   English, this machine's actual layout
#    pinyin                Simplified Chinese, forced to us  (QWERTY)
#
#  Pinyin is spelled out in Latin letters, and the muscle memory for it is
#  QWERTY -- typing "zhong" on Colemak lands on entirely different keys. fcitx5
#  applies the per-item Layout while that input method is active and restores
#  the group layout when you switch back, so English stays Colemak without a
#  second thought.
#
#  Order matters: fcitx5 uses the *first* item as the inactive state, the one
#  the trigger key toggles back to. Colemak goes first so that "IM off" means
#  English, not Pinyin.
#
#  No Japanese here, unlike the Macs' Kotoeri romaji in ../../core/darwin/
#  keyboard.nix. To add it: pacman's fcitx5-mozc, then an item with
#  Name=mozc and Layout=us.
#
#  -- The binaries are pacman's, deliberately -------------------------------
#
#    sudo pacman -S --needed fcitx5-im fcitx5-chinese-addons
#
#  fcitx5 is not installable from nix here. fcitx5-gtk and fcitx5-qt are IM
#  modules that get dlopen'd *into other applications*; built against nixpkgs'
#  Qt and GTK they would never load into Arch's Zed, Ghostty or Plasma, and
#  input would silently do nothing in every GUI app. Same class of problem as
#  the NVIDIA GL stack. So this file manages configuration only -- exactly the
#  split ../editors/zed.nix already runs with package = null.
#
#  The input method identifier below is the .conf basename the package
#  installs under share/fcitx5/inputmethod/: `pinyin` from
#  fcitx5-chinese-addons (LangCode zh_CN). It is not a free-form name -- a
#  typo means fcitx5 quietly drops the entry.
#
#  -- What managing profile costs -------------------------------------------
#
#  This is a read-only symlink into the store, and fcitx5-configtool writes
#  this file back every time you add, remove or reorder an input method. Once
#  managed here, **the GUI can no longer save those changes** -- it will appear
#  to work and then not persist. Add input methods by editing this file and
#  rebuilding.
#
#  The symlink itself survives. fcitx5 saves profile on exit, on idle
#  autosave and from the GUI, by writing a temp file and renaming it into
#  place -- but since 5.1.x it resolves the symlink first, so the temp file
#  lands in the read-only store, mkstemp fails, and the save is dropped
#  without a log line. Verified on 5.1.23: "Save before exiting..." ran and
#  ~/.config/fcitx5/profile was still the home-manager link afterwards.
#
#  A running fcitx5 keeps its in-memory profile until it restarts.
#  `fcitx5-remote -r` reloads the global config but not this file, so after a
#  rebuild that changes it:
#
#    systemctl --user restart 'app-org.fcitx.Fcitx5@autostart.service'
#
#  That is the trade README's "read-only store symlink" trap describes, taken
#  knowingly: the set of input methods and their layouts is the thing worth
#  pinning across machines, and it is not something that changes weekly.
#
#  ~/.config/fcitx5/config -- hotkeys, candidate window, theme -- is left
#  **unmanaged** on purpose. Those are preferences you tune by trying them, the
#  GUI is the right tool, and nothing about them needs to be reproducible.
#
#  -- Starting it is the session's job, not this file's ---------------------
#
#  Under niri, fcitx5 starts from pacman's /etc/xdg/autostart/
#  org.fcitx.Fcitx5.desktop, which systemd turns into
#  app-org.fcitx.Fcitx5@autostart.service. Nothing to configure.
#
#  A Plasma Wayland session instead needs KWin told to launch it:
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
    DefaultIM=pinyin

    [Groups/0/Items/0]
    Name=keyboard-us-colemak
    Layout=

    [Groups/0/Items/1]
    Name=pinyin
    Layout=us

    [GroupOrder]
    0=Default
  '';
}
