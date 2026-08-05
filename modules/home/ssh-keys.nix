{lib, ...}:
#############################################################
#
#  SSH key selection
#
#  Which machine uses which private key is a per-host fact, and should not be
#  written as an `if hostname == "..."` conditional. Declared as an option, a
#  host file needs one line: `sshKeys.primary = "...";`.
#
#  Consumers: home/jhl/common/core/{ssh,git}.nix
#
#############################################################
{
  options.sshKeys = {
    primary = lib.mkOption {
      type = lib.types.str;
      default = "id_ed25519_sk_rk";
      description = ''
        Filename (no path) of the primary private key under ~/.ssh.
        Also used as git's ssh signing key (.pub is appended automatically).

        The default is the resident sk key; machines with a YubiKey 5C Nano
        plugged in override it to id_ykmini.
      '';
    };

    extra = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["id_yk5c"];
      description = "Extra key filenames to add to ssh-agent / IdentityFile.";
    };
  };
}
