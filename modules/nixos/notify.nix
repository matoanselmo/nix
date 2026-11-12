# Power notifications to the ntfy server on matoserver (hosts/server/ntfy.nix).
# Every host says when it boots and when it shuts down or reboots. The server
# also watches the other hosts and reports one that vanishes without saying
# so (crash, power cut). The laptop warns about a low battery (laptop-power.nix).
#
# Subscribe to the `power` topic on http://matoserver:2586 in the ntfy app.
# `markers` is for the server's watcher only; don't subscribe to it.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  host = config.networking.hostName;
  # Over Tailscale (MagicDNS), so it works from anywhere on the tailnet.
  server = if host == "matoserver" then "http://localhost:2586" else "http://matoserver:2586";

  # notify <topic> <title> <message> [priority] [tags]
  # NOTIFY_RETRIES (default 5) caps the retries when the server is unreachable.
  notify = pkgs.writeShellScriptBin "notify" ''
    topic=$1 title=$2 message=$3 priority=''${4:-default} tags=''${5:-}
    exec ${lib.getExe pkgs.curl} --silent --show-error --output /dev/null \
      --max-time 5 --retry "''${NOTIFY_RETRIES:-5}" --retry-delay 3 --retry-all-errors \
      -H "Title: $title" -H "Priority: $priority" -H "Tags: $tags" \
      -d "$message" "${server}/$topic"
  '';
in
{
  environment.systemPackages = [ notify ];

  # Runs at boot, and again (ExecStop) early in shutdown: it's ordered after
  # the network and Tailscale, so it stops before they do.
  systemd.services.power-notify = {
    description = "Report boot and shutdown to ntfy";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "tailscaled.service"
    ];
    path = [ pkgs.systemd ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStopSec = 30;
    };
    script = ''
      ${lib.getExe notify} power "${host} is up" "${host} booted." default white_check_mark
    '';
    # Few retries, so an unreachable server can't hold up the shutdown.
    preStop = ''
      export NOTIFY_RETRIES=1
      if systemctl list-jobs | grep -q 'reboot.target.*start'; then
        what="is rebooting" tag=arrows_counterclockwise
      else
        what="is shutting down" tag=zzz
      fi
      # The marker tells the server's watcher that this was on purpose.
      ${lib.getExe notify} markers "${host}" "shutdown" min || true
      ${lib.getExe notify} power "${host} $what" "${host} $what." low "$tag"
    '';
  };

  # Sleep isn't announced, but it gets a marker too, or the server's watcher
  # would report a sleeping laptop as gone.
  systemd.services.power-notify-sleep = {
    description = "Tell the ntfy watcher this host is going to sleep";
    wantedBy = [ "sleep.target" ];
    before = [ "sleep.target" ];
    serviceConfig.Type = "oneshot";
    environment.NOTIFY_RETRIES = "1";
    script = ''
      ${lib.getExe notify} markers "${host}" "sleep" min || true
    '';
  };
}
