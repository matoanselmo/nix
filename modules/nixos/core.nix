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

  # patchelf 0.19.2 breaks binaries patched interpreter-first, which is how
  # gcc-arm-embedded is patched: every arm-none-eabi-* and cc1 segfault in
  # ld.so (NixOS/nixpkgs#576412, NixOS/patchelf#674). That breaks the server's
  # Klipper firmware builds and the desktop's embedded toolchain. This is the
  # package's own preFixup with the rpath set first, which works; drop it once
  # nixpkgs' patchelf has the fix.
  nixpkgs.overlays = [
    (final: prev: {
      gcc-arm-embedded = prev.gcc-arm-embedded.overrideAttrs {
        preFixup = ''
          find $out -type f | while read f; do
            patchelf "$f" > /dev/null 2>&1 || continue
            patchelf --set-rpath ${
              final.lib.makeLibraryPath [
                "$out"
                final.stdenv.cc.cc
                final.ncurses6
                final.libxcrypt-legacy
                final.xz
                final.zstd
              ]
            } "$f" || true
            patchelf --set-interpreter $(cat ${final.stdenv.cc}/nix-support/dynamic-linker) "$f" || true
          done
        '';
      };
    })
  ];

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
