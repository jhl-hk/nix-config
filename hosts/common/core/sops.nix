{
  config,
  inputs,
  isDarwin,
  ...
}:
#############################################################
#
#  sops-nix
#
#  Plumbing only -- this declares no secrets. Each consuming module declares
#  its own (e.g. hosts/common/optional/darwin/npmrc.nix), so a machine that
#  uses no ciphertext never fails to evaluate over a YAML key nobody filled in.
#
#  Decryption key: ~/.config/sops/age/keys.txt.
#  Deliberately not /etc/ssh/ssh_host_ed25519_key -- on macOS that file only
#  appears once Remote Login has been enabled, which is unreliable. Activation
#  runs as root and root can read files under the user's home, so this is fine.
#
#  WARNING: this file must exist **before** the first rebuild, or activation
#  fails.
#
#  Failure visibility: sops-install-secrets runs down two paths --
#    on switch  system.activationScripts.postActivation (activate runs with
#               set -e, so a decryption failure aborts the switch loudly --
#               it is not silent)
#    on boot    launchd.daemons.sops-install-secrets (output goes to the
#               launchd log, invisible in a terminal)
#  For the end-to-end self-check see
#  hosts/common/optional/darwin/sops-canary.nix and `just verify-sops`.
#
#############################################################
{
  imports = [
    (
      if isDarwin
      then inputs.sops-nix.darwinModules.sops
      else inputs.sops-nix.nixosModules.sops
    )
  ];

  sops.age.keyFile = "${config.hostSpec.home}/.config/sops/age/keys.txt";
}
