{ ... }:

#############################################################
#
#  Git Configuration
#
#############################################################

{
  programs.git = {
    enable = true;
    userName = "jhl";
    userEmail = "jhl@example.com";  # Change this to your email

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "vim";
    };
  };
}
