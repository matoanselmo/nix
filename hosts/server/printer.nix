# 3D printer: stock Klipper (not Kalico) + Moonraker + Mainsail, a ustreamer
# webcam, Mobileraker, smartlapse and klipper-backup. Everything runs as
# ruggy out of ~/printer_data, as it did on Ubuntu.
#
# ~/printer_data/config stays mutable (SAVE_CONFIG and klipper-backup write
# to it), so printer.cfg, the macros and hardware/*.cfg are not in this repo.
# Restore them from the backup (see CLAUDE.md). moonraker.conf there is no
# longer read: Moonraker's settings are below.
#
# MCUs must run firmware built from this Klipper. The flash commands are
# installed as klipper-flash-<mcu> (see CLAUDE.md).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  home = "/home/ruggy";
  data = "${home}/printer_data";

  # Klipper plugins go into klippy/extras.
  klipper = pkgs.klipper.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      extras=$out/lib/klipper/extras
      cp ${inputs.klipper-led-effect}/src/led_effect.py $extras/
      cp ${inputs.klipper-tmc-autotune}/autotune_tmc.py \
         ${inputs.klipper-tmc-autotune}/motor_constants.py \
         ${inputs.klipper-tmc-autotune}/motor_database.cfg $extras/
    '';
  });

  # The timelapse component goes into Moonraker's components. Moonraker's
  # installPhase doesn't run postInstall hooks, so this uses postFixup.
  moonraker = pkgs.moonraker.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      cp ${inputs.moonraker-timelapse}/component/timelapse.py $out/lib/moonraker/components/
    '';
  });

  mobilerakerPython = pkgs.python3.withPackages (
    ps: with ps; [
      coloredlogs
      requests
      websockets
      pillow
      python-dateutil
    ]
  );

  webcamPort = 8080;

  backupService = extra: {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [
      bash
      coreutils
      findutils
      gnused
      gawk
      gnugrep
      git
      openssh
      curl
      jq
      rsync
      inotify-tools
      which
    ];
    serviceConfig = {
      User = "ruggy";
      WorkingDirectory = "${home}/klipper-backup";
    }
    // extra;
  };
in
{
  services.klipper = {
    enable = true;
    package = klipper;
    user = "ruggy";
    group = "users";
    mutableConfig = true;
    configDir = "${data}/config";
    # Only written if printer.cfg is missing, i.e. before the restore.
    configFile = pkgs.writeText "printer.cfg" ''
      # Placeholder: restore ~/printer_data/config from the backup.
    '';
    apiSocket = "${data}/comms/klippy.sock";
    logFile = "${data}/logs/klippy.log";

    firmwares = {
      # FLY-DP5 mainboard, the USB-to-CAN bridge.
      mcu = {
        enable = true;
        enableKlipperFlash = true;
        configFile = ./firmware/dp5.cfg;
        canbus_uuid = "efd592e09dd8";
      };
      # EBB toolhead board.
      ebb = {
        enable = true;
        enableKlipperFlash = true;
        configFile = ./firmware/ebb.cfg;
        canbus_uuid = "69f9e88e88cc";
      };
      # BTT S2DW accelerometer.
      btt_lis2dw = {
        enable = true;
        enableKlipperFlash = true;
        configFile = ./firmware/s2dw.cfg;
        serial = "/dev/serial/by-id/usb-Klipper_rp2040_5044340418AE361C-if00";
      };
    };
  };

  services.moonraker = {
    enable = true;
    package = moonraker;
    user = "ruggy";
    group = "users";
    stateDir = data;
    address = "0.0.0.0";
    port = 7125;
    allowSystemControl = true;
    settings = {
      authorization = {
        trusted_clients = [
          "192.168.0.0/16"
          "10.0.0.0/8"
          "127.0.0.0/8"
          "169.254.0.0/16"
          "172.16.0.0/12"
          "100.0.0.0/8"
          "FC00::/7"
          "FE80::/10"
          "::1/128"
        ];
        cors_domains = [
          "*.lan"
          "*.local"
          "*://localhost"
          "*://localhost:*"
          "*://my.mainsail.xyz"
          "*://app.fluidd.xyz"
        ];
      };
      octoprint_compat = { };
      history = { };
      timelapse = {
        output_path = "/srv/timelapses/";
        frame_path = "/tmp/timelapse/";
        snapshoturl = "http://127.0.0.1:${toString webcamPort}/?action=snapshot";
        ffmpeg_binary_path = "${pkgs.ffmpeg}/bin/ffmpeg";
      };
      spoolman.server = "http://192.168.1.200:7912";
      file_manager.enable_object_processing = true;
      simplyprint = { };
    };
  };
  security.polkit.enable = true;

  # Mainsail on port 1803 only (Ruggy's choice; Mobileraker points at it).
  services.mainsail = {
    enable = true;
    hostName = "mainsail";
    nginx = {
      default = true;
      listen = [
        {
          addr = "0.0.0.0";
          port = 1803;
        }
      ];
      extraConfig = ''
        client_max_body_size 0;
        proxy_request_buffering off;
      '';
      locations."/webcam/" = {
        proxyPass = "http://127.0.0.1:${toString webcamPort}/";
        extraConfig = ''
          postpone_output 0;
          proxy_buffering off;
          proxy_ignore_headers X-Accel-Buffering;
          access_log off;
        '';
      };
    };
  };

  # mainsail.cfg and timelapse.cfg were symlinks into git checkouts in ~;
  # they now point at the pinned flake inputs.
  systemd.tmpfiles.rules = [
    "L+ ${data}/config/mainsail.cfg - - - - ${inputs.mainsail-config}/mainsail.cfg"
    "L+ ${data}/config/timelapse.cfg - - - - ${inputs.moonraker-timelapse}/klipper_macro/timelapse.cfg"
    "d ${data}/logs 0755 ruggy users - -"
    "d ${data}/comms 0755 ruggy users - -"
    "d /srv/timelapses 0755 ruggy users - -"
  ];

  # Replaces crowsnest (same camera settings as crowsnest.conf). The
  # exposure controls are set after ustreamer opens the device, which resets
  # them.
  systemd.services.ustreamer = {
    description = "ustreamer webcam";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = "ruggy";
      Group = "video";
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.ustreamer}/bin/ustreamer"
        "--device=/dev/video0"
        "--resolution=1280x720"
        "--desired-fps=30"
        "--host=0.0.0.0"
        "--port=${toString webcamPort}"
        "--allow-origin=*"
      ];
      ExecStartPost = "-${pkgs.bash}/bin/sh -c 'sleep 2; ${pkgs.v4l-utils}/bin/v4l2-ctl -d /dev/video0 -c auto_exposure=0,exposure_dynamic_framerate=0,exposure_time_absolute=100'";
      Restart = "always";
      RestartSec = 5;
    };
  };

  systemd.services.mobileraker = {
    description = "Mobileraker companion (push notifications)";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "moonraker.service"
    ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      User = "ruggy";
      ExecStart = "${mobilerakerPython}/bin/python ${inputs.mobileraker-companion}/mobileraker.py -l ${data}/logs -c ${data}/config/mobileraker.conf";
      Restart = "always";
      RestartSec = 10;
    };
  };

  # smartlapse lives in ~/smartlapse (klipper-backup backs it up). It shares
  # /tmp/timelapse with Moonraker's timelapse, and the NixOS Moonraker
  # service has a private /tmp, so it joins Moonraker's namespace.
  systemd.services.smartlapse = {
    description = "smartlapse: best-frame-per-layer timelapse";
    wantedBy = [ "multi-user.target" ];
    after = [
      "klipper.service"
      "moonraker.service"
      "ustreamer.service"
    ];
    bindsTo = [ "moonraker.service" ];
    unitConfig.JoinsNamespaceOf = "moonraker.service";
    serviceConfig = {
      User = "ruggy";
      PrivateTmp = true;
      ExecStart = "${pkgs.python3}/bin/python3 ${home}/smartlapse/smartlapse.py -c ${data}/config/smartlapse.conf";
      Restart = "always";
      RestartSec = 5;
    };
  };

  # klipper-backup stays a git checkout in ~/klipper-backup; its .env (with
  # the GitHub token) is restored from the backup and never committed.
  systemd.services.klipper-backup-on-boot = backupService {
    Type = "oneshot";
    ExecStart = "${pkgs.bash}/bin/bash -c '${home}/klipper-backup/script.sh -c \"New Backup on boot - $(date +\"%%x - %%X\")\"'";
  } // {
    description = "Klipper Backup on boot";
    wantedBy = [ "multi-user.target" ];
  };
  systemd.services.klipper-backup-filewatch = backupService {
    ExecStart = "${pkgs.bash}/bin/bash ${home}/klipper-backup/utils/filewatch.sh";
    Restart = "always";
    RestartSec = 30;
  } // {
    description = "Klipper Backup filewatch";
    wantedBy = [ "multi-user.target" ];
  };
  # Was a cron job every 4 hours.
  systemd.services.klipper-backup = backupService {
    Type = "oneshot";
    ExecStart = "${pkgs.bash}/bin/bash -c '${home}/klipper-backup/script.sh -c \"Timer backup - $(date +\"%%x - %%X\")\"'";
  } // {
    description = "Klipper Backup (timer)";
  };

  systemd.timers.klipper-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "0/4:00";
      Persistent = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ webcamPort ];
}
