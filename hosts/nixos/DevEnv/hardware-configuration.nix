{
  lib,
  modulesPath,
  ...
}:
#############################################################
#
#  DevEnv -- hardware
#
#  From `nixos-generate-config --show-hardware-config` on the installer.
#  Disk: /dev/sda, MBR, one ext4 partition labelled "nixos".
#
#############################################################
{
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];

  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
