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
        email = "valor@jianyuelab.org";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "vim";
    };
  };
}
