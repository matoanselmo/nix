{ pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.kernelModules = [ "amdgpu" ];

  # Enable hardware graphics acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Networking
  networking.hostName = "nix";
  networking.networkmanager.enable = true;

  # Time and Locale
  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_CA.UTF-8";

  # Desktop Environment
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    displayManager.lightdm.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Enable Pantheon here instead
  services.desktopManager.pantheon.enable = true;

  # Services
  services.printing.enable = true;

  # Sound (Pipewire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User Configuration
  users.users."ruggy" = {
    isNormalUser = true;
    description = "Mateus Anselmo";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.pantheon.excludePackages = [
    pkgs.epiphany
    pkgs.pantheon.elementary-calculator
    pkgs.pantheon.elementary-camera
    pkgs.pantheon.elementary-calendar
    pkgs.pantheon.elementary-code
    pkgs.pantheon.elementary-mail
    pkgs.pantheon.elementary-maps
    pkgs.pantheon.elementary-music
    pkgs.pantheon.elementary-tasks
  ];

  services.xserver.desktopManager.xterm.enable = false;
  services.tailscale.enable = true;

  environment.systemPackages = with pkgs; [
    git
    nixd
    zed-editor
    pantheon-tweaks
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # State Version - DO NOT CHANGE
  system.stateVersion = "26.05";
}
