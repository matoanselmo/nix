# Secure Boot with lanzaboote, replacing plain systemd-boot. Keys are
# generated into /var/lib/sbctl on first install; enrolling them in the
# firmware is a manual step (CLAUDE.md, "Secure Boot"), always with
# Microsoft's keys so Windows and the GPU's option ROM keep booting.
#
# Desktop only: Surface firmware can't enroll custom keys.
{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    autoGenerateKeys.enable = true;
    configurationLimit = 20;
  };

  environment.systemPackages = [ pkgs.sbctl ];
}
