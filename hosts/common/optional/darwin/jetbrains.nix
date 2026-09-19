{...}:
#############################################################
#
#  JetBrains IDEs
#
#  IntelliJ IDEA, WebStorm, GoLand and DataGrip. Split out of
#  hosts/common/optional/darwin/desktop.nix and imported by **no** host:
#  every Mac in the fleet edits code in VS Code / Zed, so four
#  multi-gigabyte IDEs plus their JBR runtimes were paying rent for
#  nothing. A machine that wants them back names this file in its own
#  imports -- nothing under hosts/common/optional/ is auto-imported.
#
#  WARNING: because onActivation.cleanup = "zap", the first switch after
#     this split **uninstalls** all four. /Applications/*.app goes away;
#     ~/Library/Application Support/JetBrains (settings, licences, local
#     history) and ~/.ivy2 / ~/.m2 do not, so re-importing this file
#     restores a configured IDE rather than a fresh one.
#
#  Not covered here: the JetBrains Toolbox cask. This fleet has never
#  declared it, and mixing it with brew-managed IDEs gives two updaters
#  fighting over the same /Applications entries -- pick one, and here that
#  is brew.
#
#############################################################
{
  darwinHomebrew.casks = [
    "intellij-idea"
    "webstorm"
    "goland"
    "datagrip"
  ];
}
