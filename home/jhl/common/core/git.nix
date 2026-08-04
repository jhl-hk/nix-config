{
  config,
  hostSpec,
  ...
}:
#############################################################
#
#  Git
#
#  身份来自 hostSpec（源头是 nix-secrets），签名密钥来自
#  modules/home/ssh-keys.nix 的选项。
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
