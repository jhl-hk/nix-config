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
        signingKey = "~/.ssh/id_ykmini.pub";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "vim";
      commit.gpgSign = true;
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      };
    };
  };
}
