{...}:
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

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };
}
