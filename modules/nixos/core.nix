# Shared by every host, including the headless server. Workstation-only
# pieces (audio, Bluetooth, NetworkManager, the desktop) are in default.nix.
{ pkgs, ... }:
{
  imports = [ ./disk.nix ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nixpkgs.config.allowUnfree = true;

  # Boots from this drive's own ESP only. Windows lives on another drive and
  # is reached from the firmware boot menu; see CLAUDE.md before adding
  # boot.loader.systemd-boot.windows.
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 20;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  networking.firewall.enable = true;

  # Log in once per machine with `sudo tailscale up`.
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  services.fwupd.enable = true;
  services.fstrim.enable = true;
  zramSwap.enable = true;

  programs.fish.enable = true;
  programs.git.enable = true;
  users.users.ruggy = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "video"
      "dialout"
      "loop"
      "plugdev"
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    micro
    btrfs-progs
    dosfstools
    exfatprogs
    ntfs3g
    nvme-cli
    unzip
  ];

  # Version the first install was made with. Don't bump it on upgrades.
  system.stateVersion = "26.11";
}
