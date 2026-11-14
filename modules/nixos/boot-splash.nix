{ pkgs, ... }:
{
  boot = {
    plymouth = {
      enable = true;
      theme = "rings";
      themePackages = [
        (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "rings" ]; })
      ];
    };
    initrd.systemd.enable = true;
    initrd.verbose = false;
    consoleLogLevel = 3;
    kernelParams = [
      "quiet"
      "splash"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
  };
}
