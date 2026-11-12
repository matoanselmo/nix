# What used to run as Docker Compose stacks under Dockge, now native NixOS
# services on the same ports. Dropped: Dockge, AMP, Ollama/Open-WebUI, Vaultwarden,
# OrcaSlicer, MongoDB, Nginx Proxy Manager (it had no proxy hosts; nginx
# itself is in printer.nix), Spoolman. Tailscale comes from core.nix.
{ lib, pkgs, ... }:
{
  # DNS for the home network on 53, web UI on 2000.
  services.pihole-ftl = {
    enable = true;
    openFirewallDNS = true;
    openFirewallWebserver = true;
    settings.dns = {
      upstreams = [
        "1.1.1.1"
        "1.0.0.1"
      ];
      listeningMode = "ALL";
    };
    # The blocklists from the old Docker Pi-hole's teleporter backup.
    lists =
      map
        (name: {
          url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/${name}.txt";
          description = "HaGeZi ${name}";
        })
        [
          "pro"
          "popupads"
          "fake"
          "nsfw"
        ];
  };
  services.pihole-web = {
    enable = true;
    ports = [ "2000" ];
  };

  # Set the SMB password once with `sudo smbpasswd -a ruggy`.
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "server string" = "matoserver";
        security = "user";
        "map to guest" = "never";
      };
      share = {
        path = "/srv/share";
        "valid users" = "ruggy";
        "guest ok" = "no";
        "read only" = "no";
        browseable = "yes";
      };
    };
  };
  systemd.tmpfiles.rules = [ "d /srv/share 0755 ruggy users - -" ];

  # From /opt/stacks/glance/config/glance.yml, minus the Docker widget.
  services.glance = {
    enable = true;
    openFirewall = true;
    settings = {
      server = {
        host = "0.0.0.0";
        port = 100;
      };
      pages = [
        {
          name = "Home";
          hide-desktop-navigation = true;
          columns = [
            {
              size = "small";
              widgets = [
                {
                  type = "calendar";
                  first-day-of-week = "monday";
                }
                {
                  type = "weather";
                  location = "Vancouver, Canada";
                  units = "metric";
                  hour-format = "12h";
                  hide-location = true;
                }
                {
                  type = "bookmarks";
                  groups = [
                    {
                      title = "Links";
                      links = [
                        {
                          title = "Mainsail";
                          url = "http://matoserver:1803";
                        }
                        {
                          title = "Tailscale admin";
                          url = "https://login.tailscale.com/admin/machines";
                        }
                      ];
                    }
                  ];
                }
              ];
            }
            {
              size = "full";
              widgets = [
                {
                  type = "server-stats";
                  servers = [
                    {
                      type = "local";
                      name = "matoserver";
                      hide-mountpoints-by-default = true;
                      mountpoints."/".hide = false;
                      mountpoints."/srv/share" = {
                        hide = false;
                        name = "NAS";
                      };
                    }
                  ];
                }
                {
                  type = "monitor";
                  title = "Services";
                  cache = "1m";
                  # Links use the WiFi address; checks go to localhost.
                  sites =
                    map
                      (site: {
                        inherit (site) title;
                        url = "http://192.168.1.200:${site.path}";
                        check-url = "http://127.0.0.1:${site.path}";
                      })
                      [
                        {
                          title = "Mainsail";
                          path = "1803";
                        }
                        {
                          title = "Moonraker";
                          path = "7125/server/info";
                        }
                        {
                          title = "Webcam";
                          path = "8080/";
                        }
                        {
                          title = "Pi-hole";
                          path = "2000/";
                        }
                        {
                          title = "Beszel";
                          path = "4000";
                        }
                        {
                          title = "Glances";
                          path = "61208";
                        }
                        {
                          title = "ntfy";
                          path = "2586";
                        }
                        {
                          title = "Atuin";
                          path = "8888";
                        }
                      ];
                }
                {
                  type = "custom-api";
                  title = "Printer";
                  cache = "30s";
                  url = "http://127.0.0.1:7125/printer/objects/query?webhooks&print_stats&display_status";
                  # print_stats keeps the last job after the printer is turned
                  # off (Klippy goes to "shutdown"), so check Klippy first.
                  template = ''
                    {{ $klippy := .JSON.String "result.status.webhooks.state" }}
                    {{ $state := .JSON.String "result.status.print_stats.state" }}
                    {{ if ne $klippy "ready" }}
                      <div class="color-subdue size-h3">{{ if eq $klippy "shutdown" }}off{{ else }}{{ $klippy }}{{ end }}</div>
                    {{ else if eq $state "printing" "paused" }}
                      <div class="flex justify-between items-center">
                        <div class="color-highlight size-h3">{{ $state }}</div>
                        <div class="size-h3">{{ .JSON.Float "result.status.display_status.progress" | mul 100.0 | toInt }}%</div>
                      </div>
                      <div class="text-truncate">{{ .JSON.String "result.status.print_stats.filename" }}</div>
                    {{ else }}
                      <div class="color-highlight size-h3">idle</div>
                    {{ end }}
                  '';
                }
                {
                  type = "iframe";
                  title = "Webcam";
                  source = "http://192.168.1.200:8080/stream";
                  height = 400;
                }
              ];
            }
            {
              size = "small";
              widgets = [
                {
                  type = "dns-stats";
                  service = "pihole-v6";
                  url = "http://127.0.0.1:2000";
                  hour-format = "12h";
                }
              ];
            }
          ];
        }
      ];
    };
  };
  # Port 100 is privileged. The module runs Glance in a user namespace,
  # where the capability wouldn't apply to the host's ports.
  systemd.services.glance.serviceConfig = {
    AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
    CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
    PrivateUsers = lib.mkForce false;
  };

  # Web UI on 61208.
  services.glances = {
    enable = true;
    openFirewall = true;
  };

  # The hub (web UI on 4000) and an agent for this machine. The agent now
  # listens on TCP 45876 (firewalled) instead of the old shared socket: in
  # the hub, edit the matoserver system to host 127.0.0.1, port 45876.
  services.beszel.hub = {
    enable = true;
    host = "0.0.0.0";
    port = 4000;
    environment.APP_URL = "http://192.168.1.200:4000";
  };
  services.beszel.agent = {
    enable = true;
    environment = {
      # The hub's public key (not a secret).
      KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJMyWtd4P98uwdFbar4n4ExdTR3YHUEMTGh2neBuxoSv";
      LISTEN = "45876";
    };
  };

  # Shell history sync for programs.atuin (modules/nixos/shell.nix), on 8888
  # with its own PostgreSQL database. The port isn't opened on the WiFi side,
  # so only the tailnet and the wired LAN reach it. Registration can be turned
  # off once the account exists.
  services.atuin = {
    enable = true;
    host = "0.0.0.0";
  };
}
