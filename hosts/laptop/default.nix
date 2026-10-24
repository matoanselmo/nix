# Laptop: Surface Pro 2017 (Pro 5, Intel Kaby Lake), on the mainline kernel.
# Touch/pen (IPTS) and the cameras need linux-surface and are left out on
# purpose; battery and power profiles work without it.
{
  imports = [
    ./hardware.nix
    ../../modules/nixos/intel-graphics.nix
    ../../modules/nixos/laptop-power.nix
  ];

  my.disk.device = "/dev/disk/by-id/nvme-SAMSUNG_KUS030202M-B000_S33JNY0K413415";
  my.disk.swapSize = "8G";

  # Skip the boot menu. Hold Space while booting to get it back (rollbacks).
  boot.loader.timeout = 0;

  programs.git.config.user = {
    name = "ruggy@laptop";
    email = "mateusanselmoguarino@gmail.com";
  };
}
