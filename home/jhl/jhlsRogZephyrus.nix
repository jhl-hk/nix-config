{...}:
#############################################################
#
#  home: jhl @ jhlsRogZephyrus
#
#  nix owns CLI tools and the development environment only.
#  GUI apps, IME, drivers and the system belong to pacman.
#
#  sops runs through home-manager here (./common/optional/sops/standalone.nix).
#  It wires llm, cloudflare, wakatime and tea.
#
#############################################################
{
  imports = [
    ./common/core
    ./common/optional/ai/codex.nix
    ./common/optional/desktop/DankMaterialShell.nix
    ./common/optional/desktop/fcitx5.nix
    ./common/optional/desktop/niri.nix
    ./common/optional/editors/zed.nix

    # Arch's nix package owns /etc/nix/nix.conf; flakes are enabled through
    # ~/.config/nix/nix.conf instead.
    ./common/optional/nix/standalone.nix

    # No system sops on this lane; decrypts as the user instead.
    ./common/optional/sops/standalone.nix
  ];

  # No id_yk5c on this machine.
  sshKeys.extra = ["id_shared"];
}
