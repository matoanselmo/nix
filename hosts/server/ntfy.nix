# ntfy push notifications on 2586 (8080 is the webcam). Not opened on the WiFi
# side, so only the tailnet and the wired LAN reach it. The Android app
# connects straight to it over Tailscale; no upstream server is involved.
#
# The watcher below pings the desktop and laptop over Tailscale every minute
# and reports one that drops off without a shutdown marker
# (modules/nixos/notify.nix), i.e. a crash, freeze or power cut.
{ lib, pkgs, ... }:
let
  watched = [
    "desktop"
    "laptop"
  ];
  port = 2586;
in
{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "http://matoserver:${toString port}";
      listen-http = ":${toString port}";
      # Long enough to cover the watcher's look-back for markers.
      cache-duration = "24h";
    };
  };

  systemd.services.power-watch = {
    description = "Report hosts that vanish without shutting down";
    path = with pkgs; [
      tailscale
      curl
      jq
      coreutils
      "/run/current-system/sw" # notify (modules/nixos/notify.nix)
    ];
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "power-watch";
    };
    script = ''
      state=/var/lib/power-watch
      for host in ${lib.escapeShellArgs watched}; do
        if tailscale ping -c 2 --timeout 5s "$host" >/dev/null 2>&1; then
          # Back: forget the old state. Its own boot message says it's up.
          rm -f "$state/$host"
          continue
        fi
        [ -e "$state/$host" ] && continue # already reported
        # Gone. Did it say it was shutting down in the last 10 minutes?
        if curl -s --max-time 10 "http://localhost:${toString port}/markers/json?poll=1&since=10m" |
          jq -e --arg h "$host" 'select(.title == $h)' >/dev/null; then
          echo shutdown >"$state/$host"
        else
          echo lost >"$state/$host"
          notify power "$host went offline" \
            "$host stopped answering without shutting down (crash, freeze or power cut)." \
            high warning
        fi
      done
    '';
  };

  systemd.timers.power-watch = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "3min";
      OnUnitActiveSec = "1min";
    };
  };
}
