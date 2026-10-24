# Desktop: Ryzen 5 5500, Radeon RX Vega 56/64.
# Windows is on a separate drive (Intel SSDPEKNU512GZ) and is never referenced
# here. Don't add it.
{
  imports = [
    ./hardware.nix
    ../../modules/nixos/amd-graphics.nix
    ../../modules/nixos/secure-boot.nix
    ../../modules/nixos/ssh.nix
  ];

  my.disk.device = "/dev/disk/by-id/nvme-CT1000P3PSSD8_25044DDBD32E";

  programs.git.config.user = {
    name = "ruggy@desktop";
    email = "mateusanselmoguarino@gmail.com";
  };
}
