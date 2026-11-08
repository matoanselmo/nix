# SMB shares on the NAS, mounted on first access and unmounted when idle, so
# being off the home network (the laptop) doesn't hang boot or file dialogs.
#
# The password is never in this repo. Create the credentials file by hand on
# each machine (see CLAUDE.md):
#   /etc/nixos/secrets/nas-smb   (root:root, mode 0600)
#     username=ruggy
#     password=...
{ lib, pkgs, ... }:
let
  server = "matoserver";
  credentials = "/etc/nixos/secrets/nas-smb";

  # share name on the NAS -> mount point
  shares = {
    share = "/mnt/nas";
  };

  mkMount = share: mountPoint: {
    name = mountPoint;
    value = {
      device = "//${server}/${share}";
      fsType = "cifs";
      options = [
        "credentials=${credentials}"
        "uid=1000"
        "gid=100"
        "noauto"
        "x-systemd.automount"
        "x-systemd.idle-timeout=600"
        "x-systemd.mount-timeout=15"
        "_netdev"
      ];
    };
  };
in
{
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems = lib.mapAttrs' mkMount shares;
}
