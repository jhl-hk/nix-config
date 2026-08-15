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
#  -- Division of labour, decided ------------------------------------------
#
#  **nix owns exactly three things here: CLI tools, dotfiles, and fonts.**
#  Everything else on this machine is pacman's. This is a settled decision, not
#  a starting point -- do not grow it without a reason that beats the three
#  below.
#
#    CLI tools   whatever the dotfiles configure: zsh, starship, git, tmux,
#                zoxide, nh, pi, wakatime-cli. Same versions as the Macs.
#    dotfiles    including config files for programs nix does *not* install --
#                zed and fcitx5 both run with their binary from pacman and
#                their configuration from here, the same arrangement the Macs
#                use against Homebrew casks.
#    fonts       ../common/core/linux.nix. Homebrew supplies them on the Macs;
#                there is no cask here, so nixpkgs does it.
#
#  What is deliberately left to pacman, and why each one is not a preference:
#
#    GUI apps      this laptop is NVIDIA + Wayland. A nixpkgs GUI app links
#                  nixpkgs' graphics stack and cannot see /usr/lib's
#                  libGLX_nvidia, so it loses acceleration or fails outright.
#                  nixGL exists, is not in nixpkgs, and wraps per app.
#    IME / plugins fcitx5-qt and fcitx5-gtk are .so files that Arch's own
#                  applications dlopen into their process. Arch and nixpkgs
#                  currently ship *identical* Qt and GTK versions, so this is
#                  not version skew -- it is that the nix build's RUNPATH pulls
#                  a second copy of the toolkit into an address space that
#                  already has one. Same reasoning for any Qt/GTK plugin.
#    system        kernel, drivers, /etc, PAM, system systemd units, the
#                  display manager. Not reachable from a home-manager scope at
#                  all.
#
#  Declarative pacman was considered and rejected: rendering a package list and
#  syncing it with paru would version-control the *names*, but pacman is a
#  rolling target with no way to pin a version, so it could never reproduce a
#  state -- only a set. If nix owning packages ever becomes the actual
#  requirement, the answer is NixOS and the empty hosts/nixos/ lane, not a
#  half-declarative layer bolted onto Arch.
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

    # Pinyin + Mozc on a QWERTY layout, over this machine's Colemak English.
    # The fcitx5 binaries come from pacman; only the profile is managed here.
    ./common/optional/desktop/fcitx5.nix
  ];

  # Graphical passphrase prompt, from the hand-written ~/.bashrc that
  # common/core/bash.nix replaces.
  #
  # Machine-specific rather than Linux-wide: the path is pacman's, and
  # ksshaskpass is KDE's implementation -- a GNOME or headless Linux box would
  # want a different one or none at all. `prefer` rather than `force` so ssh
  # still falls back to the terminal when there is no display, which is what
  # makes an ssh session into this laptop still promptable.
  home.sessionVariables = {
    SSH_ASKPASS = "/usr/bin/ksshaskpass";
    SSH_ASKPASS_REQUIRE = "prefer";
  };

  # The default primary from modules/home/ssh-keys.nix -- the resident sk key --
  # is right here: ~/.ssh/id_ed25519_sk_rk exists and is what git signs with.
  # The default `extra` is not: id_yk5c has never been on this machine, and
  # listing a missing key in IdentityFile makes ssh try and fail it first.
  sshKeys.extra = [];
}
