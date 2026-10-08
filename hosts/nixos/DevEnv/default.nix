{config, ...}:
#############################################################
#
#  DevEnv -- NixOS development machine
#
#############################################################
{
  imports = [./hardware-configuration.nix];

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

  users.users.${config.hostSpec.username}.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINVMH54ZAP0MSMznsT7Ld7qoamfK4YAC09kzrXfQmJLDAAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJQNckebiy38vNXE7nfuoXTMFXnqWhn0u99+FLiE/tzzAAAADXNzaDp5azVjLW1pbmk="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAILFYLxJPXPLjDnGdElI2iUrEAjbwQ2fjoF31hF2qJMthAAAAD3NzaDp5azVjLWJhY2t1cA=="
  ];

  # jhl has no password; key-only login.
  security.sudo.wheelNeedsPassword = false;
}
