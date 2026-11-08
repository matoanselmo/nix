# Better Than Adventure (a Minecraft beta 1.7.3 overhaul), tailnet only.
#
# Everything lives on the NAS in /srv/share/minecraft/bta (/mnt/nas/... on
# the workstations), including server.jar, which is dropped in by hand and
# not in this repo. Update BTA by replacing server.jar and restarting.
#
# Console: `mc <command>` (e.g. `mc say hi`), output in
# `journalctl -u minecraft-bta -f`. Port 25565 is only reachable over
# Tailscale and the wired LAN (trusted interfaces); the WiFi uplink stays shut.
{ pkgs, ... }:
let
  dir = "/srv/share/minecraft/bta";
  stdin = "/run/minecraft-bta.stdin";

  # Ask the server to save and stop, then wait for it so systemd doesn't
  # SIGKILL it mid-save.
  stop = pkgs.writeShellScript "minecraft-bta-stop" ''
    echo stop > ${stdin}
    while kill -0 "$1" 2>/dev/null; do sleep 1; done
  '';
in
{
  systemd.sockets.minecraft-bta = {
    bindsTo = [ "minecraft-bta.service" ];
    socketConfig = {
      ListenFIFO = stdin;
      SocketMode = "0660";
      SocketUser = "ruggy";
      SocketGroup = "users";
      RemoveOnStop = true;
      FlushPending = true;
    };
  };

  systemd.services.minecraft-bta = {
    description = "Better Than Adventure server";
    wantedBy = [ "multi-user.target" ];
    requires = [ "minecraft-bta.socket" ];
    after = [
      "network.target"
      "minecraft-bta.socket"
    ];
    unitConfig.RequiresMountsFor = dir;

    serviceConfig = {
      ExecStart = "${pkgs.jdk17_headless}/bin/java -Xms1G -Xmx4G -jar server.jar nogui";
      ExecStop = "${stop} $MAINPID";
      Restart = "on-failure";
      User = "ruggy";
      Group = "users";
      WorkingDirectory = dir;
      StandardInput = "socket";
      StandardOutput = "journal";
      StandardError = "journal";

      # Klipper and Pi-hole come first.
      CPUWeight = 20;
      IOWeight = 20;
      Nice = 10;
      MemoryMax = "5G";
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "mc" ''echo "$*" > ${stdin}'')
  ];
}
