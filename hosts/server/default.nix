# Server (hostname matoserver): home server, NAS, router for the wired LAN
# and 3D printer host. Headless: core.nix only, no desktop or Home Manager.
{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./networking.nix
    ./printer.nix
    ./services.nix
    ./power.nix
    ../../modules/nixos/intel-graphics.nix
    ../../modules/nixos/ssh.nix
  ];

  # 1 TB drive: a small system partition, and the rest is the NAS.
  my.disk.device = "/dev/disk/by-id/nvme-CT1000P3PSSD8_25044DDBD32E";
  my.disk.rootSize = "128G";
  disko.devices.disk.main.content.partitions.nas = {
    size = "100%"; # disko places 100% partitions last
    content = {
      type = "btrfs";
      extraArgs = [
        "-f"
        "-L"
        "nas"
      ];
      subvolumes = {
        "/@share" = {
          mountpoint = "/srv/share";
          mountOptions = [
            "compress=zstd"
            "noatime"
          ];
        };
        # For snapper (below); nested, so it's left out of the snapshots.
        "/@share/.snapshots" = { };
      };
    };
  };
  services.btrfs.autoScrub.fileSystems = [ "/srv/share" ];

  # Undo for the NAS: browse old versions in /srv/share/.snapshots.
  services.snapper.configs.share = {
    SUBVOLUME = "/srv/share";
    ALLOW_USERS = [ "ruggy" ];
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_LIMIT_HOURLY = 6;
    TIMELINE_LIMIT_DAILY = 7;
    TIMELINE_LIMIT_WEEKLY = 4;
    TIMELINE_LIMIT_MONTHLY = 6;
    TIMELINE_LIMIT_YEARLY = 0;
  };

  users.users.ruggy = {
    extraGroups = [
      "render"
      "tty"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDS2flJu/wERIxw2nO9TWcoITav+2A7e+gf0yyJ1lssp mateusanselmoguarino@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJxYrEmOKkgDfycsqloWrPW8uj2L1K9rVJ6VP38cHuNR mato@matopc"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEwGMQG76woMK9dJz87xRI+NwE2at9IfdfSHMrmN3HZC ruggy@desktop"
    ];
  };

  services.fail2ban.enable = true;

  environment.systemPackages = with pkgs; [
    htop
    tmux
    v4l-utils
    can-utils
    inotify-tools
  ];

  programs.git.config.user = {
    name = "ruggy@matoserver";
    email = "mateusanselmoguarino@gmail.com";
  };
}
