# Battery and power profiles on the Surface Pro 5, with the mainline kernel.
# Battery state comes from the Surface Aggregator Module (mainline since 5.12)
# and performance modes from surface_platform_profile (since 5.13), which
# power-profiles-daemon drives through /sys/firmware/acpi/platform_profile.
{
  boot.kernelModules = [
    "surface_aggregator"
    "surface_aggregator_registry"
    "surface_acpi_notify"
    "surface_platform_profile"
  ];

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.thermald.enable = true;
}
