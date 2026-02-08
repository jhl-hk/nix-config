{ ... }:

#############################################################
#
#  Git Configuration
#
#############################################################

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "jhl-hk";
        email = "ja@jhl.hk";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "vim";
    };
  };
}
