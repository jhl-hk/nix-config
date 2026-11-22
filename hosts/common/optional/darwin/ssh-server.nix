{
  config,
  lib,
  ...
}:
#############################################################
#
#  SSH server (macOS)
#
#  Remote Login on, key-only. Authorized keys come from
#  hosts/common/users/jhl/authorized-keys.nix.
#
#############################################################
{
  services.openssh = {
    enable = true;
    extraConfig = ''
      PermitRootLogin no
      PasswordAuthentication no
      KbdInteractiveAuthentication no
    '';
  };

  users.users.${config.hostSpec.username}.openssh.authorizedKeys.keys =
    import (lib.custom.relativeToRoot "hosts/common/users/jhl/authorized-keys.nix");
}
