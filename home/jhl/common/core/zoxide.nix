{pkgs, ...}:
#############################################################
#
#  Zoxide -- frecency-ranked directory jumping
#
#  Adopted from https://github.com/ChanningHe/nix-config.
#
#  `--cmd cd` makes zoxide *shadow* cd rather than adding a `z` alias, so
#  `cd nix-config` from anywhere jumps to the highest-ranked match instead
#  of failing. Plain `cd ./relative/path` still behaves normally -- zoxide
#  only consults its database when the argument is not an existing path.
#  The real builtin is still reachable as `\cd` if a script needs it.
#
#  `cdi` (the interactive picker) shells out to fzf, which is why fzf is
#  installed here. It is deliberately *just the binary*: programs.fzf.enable
#  would also install the shell integration and rebind Ctrl+R and Ctrl+T,
#  which is a bigger change than this file is for.
#
#  Zsh integration lands at mkOrder 851 in .zshrc -- after the completion
#  zstyles in ./zsh.nix (650) and after autosuggestions (700).
#
#############################################################
{
  home.packages = [pkgs.fzf];

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    options = ["--cmd" "cd"];
  };
}
