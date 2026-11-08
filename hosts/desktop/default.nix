# Desktop: Ryzen 5 5500, Radeon RX Vega 56/64.
# Windows is on a separate drive (Intel SSDPEKNU512GZ) and is never referenced
# here. Don't add it.
{ pkgs, inputs, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/nixos/amd-graphics.nix
    ../../modules/nixos/secure-boot.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/embedded.nix
  ];

  environment.systemPackages = [
    inputs.solidcraft.packages.${pkgs.stdenv.hostPlatform.system}.solidcraft
    pkgs.rustup
    pkgs.gcc
    pkgs.jetbrains.idea
    pkgs.nodejs
  ];

  my.disk.device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K178413";
}
