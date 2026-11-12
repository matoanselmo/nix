# Battery and power profiles on the Surface Pro 5, with the mainline kernel.
# Battery state comes from the Surface Aggregator Module (mainline since 5.12)
# and performance modes from surface_platform_profile (since 5.13), which
# power-profiles-daemon drives through /sys/firmware/acpi/platform_profile.
{ pkgs, ... }:
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

  # Low battery warnings through ntfy (notify.nix): at 20% and again at 10%,
  # once each per discharge.
  systemd.services.battery-notify = {
    description = "Warn about a low battery through ntfy";
    path = [ pkgs.coreutils "/run/current-system/sw" ];
    serviceConfig.Type = "oneshot";
    script = ''
      bat=$(echo /sys/class/power_supply/BAT*)
      [ -e "$bat/capacity" ] || exit 0
      level=$(cat "$bat/capacity") status=$(cat "$bat/status")
      sent=/run/battery-notify
      if [ "$status" != Discharging ]; then
        rm -f "$sent"
        exit 0
      fi
      last=$(cat "$sent" 2>/dev/null || echo 100)
      for threshold in 10 20; do
        if [ "$level" -le "$threshold" ] && [ "$last" -gt "$threshold" ]; then
          priority=high
          [ "$threshold" = 10 ] && priority=urgent
          notify power "laptop battery at $level%" \
            "The laptop is at $level% and discharging." "$priority" battery
          echo "$threshold" >"$sent"
          break
        fi
      done
    '';
  };
  systemd.timers.battery-notify = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "2min";
    };
  };
}
