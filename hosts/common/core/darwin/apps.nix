{...}:
#############################################################
#
#  Homebrew manifest -- the baseline every Mac gets
#
#  Data only. The wiring, and the beta gate on masApps, live in
#  modules/hosts/darwin/homebrew/.
#
#  What stays here is what a machine needs to be a usable development box over
#  ssh: a shell, git, the two package managers, and the YubiKey/askpass pair
#  that makes authentication work at all. Everything heavier was split out so
#  a minimal machine can decline it:
#
#    hosts/common/optional/darwin/desktop.nix     GUI apps + Mac App Store
#    hosts/common/optional/darwin/dev-extras.nix  the rest of the CLI toolbox
#
#  jhlsMacBookAir imports neither, which is the whole point of the split --
#  core is what every machine gets, so anything one machine can live without
#  does not belong in it.
#
#  taps / brews / casks are listOf, so definitions from other modules
#  concatenate -- which is how each optional appends its own. Each tap now
#  sits with the formula that needs it rather than all of them living here.
#
#############################################################
{
  darwinHomebrew = {
    taps = [
      {
        name = "oven-sh/bun";
        trusted = true;
      }
      {
        name = "theseal/ssh-askpass";
        trusted = true;
      }
    ];

    brews = [
      "bun" # Package manager
      "node"
      "git"
      "just"
      "openssh"
      "tree"
      "telnet"
      "mas"
      "gh"
      "tmux"
      "xcodes"
      "age-plugin-yubikey"
      "ssh-askpass"
      "ykman"
    ];
  };
}
