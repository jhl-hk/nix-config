{ ... }:

#############################################################
#
#  Git Configuration
#
#############################################################

{
  programs.git = {
    enable = true;
    userName = "jhl-hk";
    userEmail = "valor@jianyuelab.org";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "vim";
    };
  };
}
