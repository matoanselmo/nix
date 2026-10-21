# Hand-written from `lspci -k` on the running openSUSE install, since
# nixos-generate-config can't run there. On install day, compare it with
#   nixos-generate-config --no-filesystems --show-hardware-config
# and take anything that differs. Filesystems come from disk.nix (disko).
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
