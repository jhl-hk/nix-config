{config, ...}:
#############################################################
#
#  SSH
#
#  The cross-platform half. Key filenames come from the options in
#  modules/home/ssh-keys.nix, no longer from a hostname conditional.
#
#  The Homebrew ssh-agent shell logic for macOS lives in
#  ./darwin/ssh-agent.nix.
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
