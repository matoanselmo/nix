# One drive: an ESP and a btrfs partition with subvolumes, declared with disko.
# disko only writes to the disk when you run it from the installer (see
# CLAUDE.md); evaluating or building this config never touches a drive.
{ config, lib, ... }:
let
  btrfsOpts = [
    "compress=zstd"
    "noatime"
  ];
in
{
  options.my.disk = {
    device = lib.mkOption {
      type = lib.types.str;
      example = "/dev/disk/by-id/nvme-CT1000P3PSSD8_25044DDBD32E";
      description = ''
        The whole drive NixOS is installed on, by its /dev/disk/by-id path so
        it can never resolve to a different drive.
      '';
    };
    swapSize = lib.mkOption {
      type = lib.types.str;
      default = "16G";
      description = "Size of the swapfile in the @swap subvolume.";
    };
  };

  config = {
    disko.devices.disk.main = {
      type = "disk";
      inherit (config.my.disk) device;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            priority = 1;
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "-L"
                "nixos"
              ];
              subvolumes = {
                "/@" = {
                  mountpoint = "/";
                  mountOptions = btrfsOpts;
                };
                # Snapper needs a .snapshots subvolume inside each subvolume
                # it manages. Nested subvolumes are left out of their
                # parent's snapshots.
                "/@/.snapshots" = { };
                "/@home" = {
                  mountpoint = "/home";
                  mountOptions = btrfsOpts;
                };
                "/@home/.snapshots" = { };
                "/@nix" = {
                  mountpoint = "/nix";
                  mountOptions = btrfsOpts;
                };
                "/@log" = {
                  mountpoint = "/var/log";
                  mountOptions = btrfsOpts;
                };
                "/@swap" = {
                  mountpoint = "/swap";
                  mountOptions = [ "noatime" ];
                  swap.swapfile.size = config.my.disk.swapSize;
                };
              };
            };
          };
        };
      };
    };

    services.snapper.configs = {
      home = {
        SUBVOLUME = "/home";
        ALLOW_USERS = [ "ruggy" ];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 6;
        TIMELINE_LIMIT_DAILY = 7;
        TIMELINE_LIMIT_WEEKLY = 4;
        TIMELINE_LIMIT_MONTHLY = 3;
        TIMELINE_LIMIT_YEARLY = 0;
      };
      # NixOS generations already cover rolling back the system; these catch
      # stray state outside /home and /nix.
      root = {
        SUBVOLUME = "/";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 0;
        TIMELINE_LIMIT_DAILY = 3;
        TIMELINE_LIMIT_WEEKLY = 2;
        TIMELINE_LIMIT_MONTHLY = 0;
        TIMELINE_LIMIT_YEARLY = 0;
      };
    };

    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };
  };
}
