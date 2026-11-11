# Laptop: Surface Pro 2017 (Pro 5, Intel Kaby Lake), on the mainline kernel.
# Touch/pen (IPTS) and the cameras need linux-surface and are left out on
# purpose; battery and power profiles work without it.
#
{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/nixos/intel-graphics.nix
    ../../modules/nixos/laptop-power.nix
  ];

  environment.systemPackages = [
    pkgs.openjdk25
    (pkgs.writeShellScriptBin "wakepc" ''
      exec ssh matoserver wakepc
    '')
  ];

  my.disk.device = "/dev/disk/by-id/nvme-SAMSUNG_KUS030202M-B000_S33JNY0K413415";
  my.disk.swapSize = "8G";

  # Helium instead of Zen, on this machine only.
  my.browser = "helium";

  # Skip the boot menu. Hold Space while booting to get it back (rollbacks).
  boot.loader.timeout = 0;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      alsa-lib
      udev
    ];
  };
}
