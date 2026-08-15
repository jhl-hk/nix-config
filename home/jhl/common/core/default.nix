{
  lib,
  hostSpec,
  ...
}:
#############################################################
#
#  Home Core -- the baseline every machine gets
#
#  The imports here are **hand-written**, not scanPaths. core is "the things I
#  want everywhere", and a hand-written list lets you see the whole dotfile
#  surface at a glance. Anything that should be switchable per machine belongs
#  in common/optional/.
#
#  hostSpec arrives as a **function argument** via extraSpecialArgs, not as an
#  option -- home modules destructure { hostSpec, ... } at the function head
#  rather than reading NixOS's config.
#
#############################################################
let
  platform =
    if hostSpec.isDarwin
    then "darwin"
    else "linux";
in {
  imports = [
    # Option-providing home modules, auto-scanned
    (lib.custom.relativeToRoot "modules/home")

    # The platform half. This line is ordinary path interpolation, not magic
    # -- renaming darwin.nix / linux.nix makes that platform fail to evaluate.
    #
    # Note the split is darwin/linux, not darwin/nixos: the non-Darwin side is
    # shared by NixOS and by the standalone home-manager machines under
    # hosts/home/, which have no NixOS underneath them at all.
    ./${platform}.nix

    ./git.nix
    ./nh.nix
    ./ssh.nix
    ./zsh.nix
    ./starship.nix
    ./zoxide.nix
    ./tmux.nix
    ./claude.nix
    ./llm.nix
    ./opencode.nix
    ./pi.nix
    ./wakatime.nix
  ];

  home = {
    username = hostSpec.username;
    homeDirectory = hostSpec.home;
    stateVersion = "26.05";

    # We mix unstable nixpkgs with stable darwin, so turn off the version
    # consistency check
    enableNixpkgsReleaseCheck = false;

    sessionVariables = {
      EDITOR = "vim";
    };

    # allowed_signers, used to verify git commit signatures. The contents are
    # public keys, but they are identity data, so they live in the cleartext
    # half of nix-secrets.
    file.".ssh/allowed_signers".text = lib.concatLines hostSpec.sshAllowedSigners;
  };

  programs.home-manager.enable = true;
}
