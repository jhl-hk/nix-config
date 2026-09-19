{...}:
#############################################################
#
#  Visual Studio Code
#
#  Split out of hosts/common/optional/darwin/desktop.nix so a machine can
#  take the rest of the desktop set without VS Code. Imported only by
#  SeandeMac-Studio; jhlsMacBookPro takes desktop.nix but not this.
#
#  WARNING: onActivation.cleanup = "zap" means dropping this import from a
#     host **uninstalls** VS Code on the next switch. ~/Library/Application
#     Support/Code and ~/.vscode (settings, extensions) are left behind, so
#     re-importing it restores a configured editor.
#
#############################################################
{
  darwinHomebrew.casks = [
    "visual-studio-code"
  ];
}
