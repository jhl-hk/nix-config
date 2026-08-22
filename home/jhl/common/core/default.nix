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
    ./bash.nix
    ./zsh.nix
    ./starship.nix
    ./zoxide.nix
    ./tmux.nix
    ./claude.nix
    ./jyl-usage.nix
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

      # Needed when driving sops by hand. The path is the same one
      # hosts/common/core/sops.nix points sops.age.keyFile at.
      #
      # A session variable rather than a line in one shell's rc file: it lands
      # in hm-session-vars.sh, which ./bash.nix and ./zsh.nix both source, so
      # `just sops-edit` behaves the same whichever shell you are standing in.
      SOPS_AGE_KEY_FILE = "${hostSpec.home}/.config/sops/age/keys.txt";
    };

    # Shell-agnostic on purpose. home-manager copies home.shellAliases into
    # programs.bash.shellAliases *and* programs.zsh.shellAliases
    # (modules/home-environment.nix), so declaring them once here is what keeps
    # bash and zsh from drifting apart -- which is exactly what happened to the
    # repo path below when it was written out by hand in two places.
    shellAliases = let
      # This used to be hard-coded as ~/Documents/nix-config, which broke all
      # three aliases once the repo moved under nix-src/.
      flakeDir = "${hostSpec.home}/Documents/nix-src/nix-config";
    in {
      sysnew = "cd ${flakeDir} && just rebuild && cd -";
      sysup = "cd ${flakeDir} && just update && cd -";
      syscl = "cd ${flakeDir} && just clean && cd -";
    };

    # allowed_signers, used to verify git commit signatures. The contents are
    # public keys, but they are identity data, so they live in the cleartext
    # half of nix-secrets.
    file.".ssh/allowed_signers".text = lib.concatLines hostSpec.sshAllowedSigners;
  };

  programs.home-manager.enable = true;
}
