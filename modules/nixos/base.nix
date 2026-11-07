# Workstation basics (desktop and laptop): networking, audio, Bluetooth.
# What every host shares, the server included, is in core.nix.
{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.networkmanager.enable = true;
  users.users.ruggy.extraGroups = [ "networkmanager" ];

  hardware.bluetooth.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  programs.nix-ld.enable = true;
}
