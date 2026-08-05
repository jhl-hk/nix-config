{pkgs, ...}:
#############################################################
#
#  Dev shell -- `nix develop`
#
#  Holds the tools needed to *operate this repo*, not system packages.
#  sops / age live here rather than in hosts/ on purpose, so editing a secret
#  once doesn't mean installing them on every machine.
#
#############################################################
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    just
    alejandra # formatter, matches the flake's formatter output
    deadnix # finds unused bindings

    sops
    age
    ssh-to-age

    jq
    yq-go
    gum # for interactive scripts
  ];

  shellHook = ''
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    if [ ! -f "$SOPS_AGE_KEY_FILE" ]; then
      printf '\033[33m⚠ %s not found\033[0m\n' "$SOPS_AGE_KEY_FILE"
      printf '  Both sops decryption and activation need it. To generate:\n'
      printf '    mkdir -p ~/.config/sops/age && age-keygen -o "$SOPS_AGE_KEY_FILE"\n\n'
    fi
    just --list
  '';
}
