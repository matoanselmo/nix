# Low idle power, as on Ubuntu: powertop's auto-tune at boot, thermald, and
# SATA link power management.
{
  powerManagement.powertop.enable = true;
  services.thermald.enable = true;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="min_power"
  '';
}
