# Two networks:
#   wlxa86e84a1ca08  TP-Link USB WiFi, uplink to the TELUS router. Static
#                    192.168.1.200; everything else reaches the server here.
#   enp3s0           Realtek wired port, a private LAN (192.168.100.0/24)
#                    that the server routes (NAT) and hands out DHCP on.
# Plus can0 for the printer (FLY-DP5 USB-to-CAN bridge, gs_usb).
#
# The WiFi PSK is never in this repo. Create it by hand (see CLAUDE.md):
#   /etc/nixos/secrets/wifi   (root:root, mode 0600)
#     psk_home=<passphrase>
{ pkgs, ... }:
let
  wifi = "wlxa86e84a1ca08";
  lan = "enp3s0";
in
{
  networking.useNetworkd = true;
  networking.useDHCP = false;

  # Pi-hole owns port 53 (services.nix), so no resolved stub listener. The
  # server itself resolves through the router and Cloudflare, so DNS works
  # even while Pi-hole is down.
  services.resolved.enable = false;
  networking.nameservers = [
    "192.168.1.254"
    "1.1.1.1"
  ];

  # The TP-Link stick starts as a driver CD (0bda:1a2b) and only becomes
  # the WiFi adapter after usb_modeswitch flips it.
  hardware.usb-modeswitch.enable = true;
  # In WiFi mode it's 2357:0141, driven by rtw89_8852au, which the default
  # (6.18) kernel doesn't have.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.wireless = {
    enable = true;
    interfaces = [ wifi ];
    secretsFile = "/etc/nixos/secrets/wifi";
    networks."TELUS9825".pskRaw = "ext:psk_home";
  };

  systemd.network.networks = {
    "10-wifi" = {
      matchConfig.Name = wifi;
      address = [ "192.168.1.200/24" ];
      routes = [ { Gateway = "192.168.1.254"; } ];
      networkConfig.IPv6AcceptRA = true;
    };
    "10-lan" = {
      matchConfig.Name = lan;
      address = [ "192.168.100.1/24" ];
      # Nothing may be plugged in; don't hold up boot for it.
      linkConfig.RequiredForOnline = "no";
      networkConfig.ConfigureWithoutCarrier = true;
    };
    "25-can" = {
      matchConfig.Name = "can*";
      canConfig.BitRate = "1M";
      linkConfig.RequiredForOnline = "no";
    };
  };

  boot.kernelModules = [
    "can"
    "can_raw"
    "gs_usb"
  ];
  services.udev.extraRules = ''
    SUBSYSTEM=="net", ACTION=="change|add", KERNEL=="can*", ATTR{tx_queue_len}="1024"
  '';

  # Route the wired LAN out through the WiFi.
  networking.nat = {
    enable = true;
    internalInterfaces = [ lan ];
    externalInterface = wifi;
  };

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config.interfaces = [ lan ];
      lease-database = {
        type = "memfile";
        persist = true;
        name = "/var/lib/kea/dhcp4.leases";
      };
      valid-lifetime = 600;
      max-valid-lifetime = 7200;
      subnet4 = [
        {
          id = 1;
          subnet = "192.168.100.0/24";
          pools = [ { pool = "192.168.100.10 - 192.168.100.100"; } ];
          option-data = [
            {
              name = "routers";
              data = "192.168.100.1";
            }
            {
              name = "domain-name-servers";
              data = "8.8.8.8, 8.8.4.4";
            }
          ];
        }
      ];
    };
  };

  networking.firewall = {
    # The wired LAN and the tailnet are trusted; the WiFi side gets the
    # service ports below. 22 comes from services.openssh.
    trustedInterfaces = [
      lan
      "tailscale0"
    ];
    allowedTCPPorts = [
      1803 # Mainsail
      7125 # Moonraker
      4000 # Beszel
    ];
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "wakepc" ''
      exec ${pkgs.wakeonlan}/bin/wakeonlan A8:A1:59:E8:DA:EC
    '')
  ];
}
