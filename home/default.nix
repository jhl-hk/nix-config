{ config, pkgs, hostname, ... }:

#############################################################
#
#  Home Manager Configuration for jhl
#  User-specific environment and dotfiles
#
#############################################################

{
  imports = [
    ./programs
    ./shell
  ];

  # Primary SSH key for this host, consumed by ./programs/ssh.nix and
  # ./programs/git.nix. Only the MacBook Pro carries the YubiKey 5C Nano
  # ("ykmini"); every other host authenticates with the resident sk key.
  _module.args.sshPrimaryKey =
    if hostname == "jhlsMacBookPro" then "id_ykmini" else "id_ed25519_sk_rk";

  # Home Manager settings
  home = {
    username = "jhl";
    homeDirectory = "/Users/jhl";
    stateVersion = "26.05";

    # Disable version mismatch check (we're using unstable nixpkgs with stable darwin)
    enableNixpkgsReleaseCheck = false;

    # Environment variables
    sessionVariables = {
      EDITOR = "vim";
    };

    # SSH allowed signers for git commit verification
    file.".ssh/allowed_signers".text = ''
      ja@jhl.hk sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINVMH54ZAP0MSMznsT7Ld7qoamfK4YAC09kzrXfQmJLDAAAABHNzaDo=
    '';
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
