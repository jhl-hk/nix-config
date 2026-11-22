{
  config,
  lib,
  ...
}:
#############################################################
#
#  DevEnv -- NixOS development machine
#
#############################################################
{
  imports =
    [./hardware-configuration.nix]
    ++ map lib.custom.relativeToRoot [
      "hosts/common/optional/nixos/dev.nix"
      "hosts/common/optional/nixos/forgejo.nix"
      "hosts/common/optional/common/llm.nix"
    ];

  hostSpec = {
    hostName = "DevEnv";
    isServer = true;
    useWindowManager = false;
  };

  # SeaBIOS guest: no EFI, so GRUB on the MBR.
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  networking = {
    useDHCP = false;
    interfaces.ens18.ipv4.addresses = [
      {
        address = "10.100.250.198";
        prefixLength = 24;
      }
    ];
    defaultGateway = "10.100.250.1";
    nameservers = ["1.1.1.1"];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  users.users.${config.hostSpec.username}.openssh.authorizedKeys.keys =
    import (lib.custom.relativeToRoot "hosts/common/users/jhl/authorized-keys.nix");

  # jhl has no password; key-only login.
  security.sudo.wheelNeedsPassword = false;
}
