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

  my.disk.device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K178413";

  users.users.ruggy = {
    extraGroups = [
      "render"
      "tty"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDS2flJu/wERIxw2nO9TWcoITav+2A7e+gf0yyJ1lssp mateusanselmoguarino@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJxYrEmOKkgDfycsqloWrPW8uj2L1K9rVJ6VP38cHuNR mato@matopc"
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
