{...}:
#############################################################
#
#  home: jhl @ jhlsRogZephyrus
#
#  nix owns CLI tools and the development environment only.
#  GUI apps, IME, drivers and the system belong to pacman.
#
#  No sops on this lane: llm and wakatime run without their keys until an age
#  key for this machine is added to ../nix-secrets.
#
#############################################################
{
  imports = [
    ./common/core
    ./common/optional/ai/codex.nix

    # Arch's nix package owns /etc/nix/nix.conf; flakes are enabled through
    # ~/.config/nix/nix.conf instead.
    ./common/optional/nix/standalone.nix
  ];
}
