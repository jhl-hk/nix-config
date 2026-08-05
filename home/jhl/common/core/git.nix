{
  config,
  hostSpec,
  ...
}:
#############################################################
#
#  Git
#
#  Identity comes from hostSpec (sourced from nix-secrets); the signing key
#  comes from the options in modules/home/ssh-keys.nix.
#
#############################################################
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = hostSpec.userFullName;
        email = hostSpec.email.user;
        signingKey = "~/.ssh/${config.sshKeys.primary}.pub";
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
