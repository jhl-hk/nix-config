{...}:
#############################################################
#
#  home: jhl @ jhlsArchLinux
#
#  The only machine on the standalone home-manager lane. Unlike the Macs, this
#  file is the *whole* configuration: there is no hosts/darwin/<Name> sibling
#  doing system work, because Arch owns the system.
#
#  Activate with `just rebuild`, same as everywhere else -- scripts/rebuild.sh
#  branches on uname and drives `home-manager switch` here instead of
#  `darwin-rebuild switch`.
#
#  -- Division of labour --------------------------------------------------
#
#  pacman keeps the system and the GUI apps: zed (the `zeditor` package),
#  ghostty, the desktop, the kernel. nix owns dotfiles and the CLI tools those
#  dotfiles configure -- which is why programs.zed-editor below still runs with
#  package = null, exactly as it does against the Homebrew cask on the Macs.
#
#  -- Secrets are not wired up yet ----------------------------------------
#
#  Every sops secret in this repo is declared in the system scope
#  (hosts/common/optional/darwin/*.nix), and this machine has no system scope.
#  So the two consumers that want a key run without one:
#
#    llm       home/jhl/common/core/llm.nix exports the key only when
#              /run/secrets/llm/api_key is readable, so it simply does not
#              export it here. opencode, pi and Zed still get their provider
#              and model list; requests will 401 until a key exists.
#    wakatime  ~/.wakatime.cfg points api_key_vault_cmd at the same missing
#              path. wakatime-cli logs to ~/.wakatime/wakatime.log and keeps
#              going, so this is quiet rather than loud.
#
#  Turning them on is user-operated work that has to happen in ../nix-secrets
#  first -- this machine has no age key at all yet:
#
#    1. just age-key ~/.config/sops/age/keys.txt
#    2. add the printed public key to ../nix-secrets/.sops.yaml
#    3. just rekey, then commit + push in ../nix-secrets
#    4. just update-nix-secrets
#
#  Only then is it worth adding sops-nix's homeManagerModules.sops here and
#  repointing llm.apiKeyFile (modules/home/llm.nix) plus the vault command in
#  common/core/wakatime.nix at $XDG_RUNTIME_DIR/secrets, which is where the
#  home-manager sops module lands secrets instead of /run/secrets.
#
#############################################################
{
  imports = [
    ./common/core
    ./common/optional/editors/zed.nix

    # Arch's nix package owns /etc/nix/nix.conf, so flakes get enabled through
    # ~/.config/nix/nix.conf instead. Read the header before copying this to a
    # Mac -- on Darwin the same file would outrank nix-darwin's.
    ./common/optional/nix/standalone.nix
  ];

  # The default primary from modules/home/ssh-keys.nix -- the resident sk key --
  # is right here: ~/.ssh/id_ed25519_sk_rk exists and is what git signs with.
  # The default `extra` is not: id_yk5c has never been on this machine, and
  # listing a missing key in IdentityFile makes ssh try and fail it first.
  sshKeys.extra = [];
}
