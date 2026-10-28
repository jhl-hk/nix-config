{
  config,
  hostSpec,
  ...
}:
#############################################################
#
#  SSH
#
#  The cross-platform half. Key filenames come from the options in
#  modules/home/ssh-keys.nix, no longer from a hostname conditional.
#
#  Per-host blocks come from hostSpec.sshClientsInfo (nix-secrets,
#  nix/ssh-clients.nix).
#
#  The Homebrew ssh-agent shell logic for macOS lives in
#  ./darwin/ssh-agent.nix.
#
#############################################################
let
  keys = [config.sshKeys.primary] ++ config.sshKeys.extra;
in {
  # Public half of the shared key. The private half is decrypted by sops:
  # hosts/common/core/darwin/ssh-shared-key.nix on the Macs,
  # home/jhl/common/optional/sops/standalone.nix on the standalone lane.
  home.file.".ssh/id_shared.pub".text = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPXyHGJrGjtSQCgGjQqT28PSXgxtHT8u+Z/j3ioZF0X/ jhl-shared
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings =
      hostSpec.sshClientsInfo
      // {
        "*" = {
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
  };
}
