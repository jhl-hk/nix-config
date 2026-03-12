{ config, pkgs, ... }:

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

  # Home Manager settings
  home = {
    username = "jhl";
    homeDirectory = "/Users/jhl";
    stateVersion = "25.11";

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
