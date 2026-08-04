{config, ...}:
#############################################################
#
#  SSH
#
#  跨平台的那半。密钥文件名来自 modules/home/ssh-keys.nix 的选项，
#  不再靠 hostname 条件判断。
#
#  macOS 上那套 Homebrew ssh-agent 的 shell 逻辑在
#  ./darwin/ssh-agent.nix。
#
#############################################################
let
  keys = [config.sshKeys.primary] ++ config.sshKeys.extra;
in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      ForwardAgent = true;
      ServerAliveCountMax = 3;
      ServerAliveInterval = 60;
      IdentityFile = map (k: "~/.ssh/${k}") keys;
      AddKeysToAgent = "yes";
      Compression = "yes";
      ControlMaster = "auto";
      ControlPath = "~/.ssh/master-%r@%n:%p";
      ControlPersist = "10m";
    };
  };
}
