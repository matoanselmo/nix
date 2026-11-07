# matoserver: Intel Kaby Lake desktop board, Samsung MZVLW256 NVMe.
# Written by hand from the running Ubuntu install (drivers in use: nvme,
# ahci, xhci_hcd). Regenerate with `nixos-generate-config --show-hardware-config`
# after installing, and keep only the initrd/kernel module lines; disko owns
# fileSystems.
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
