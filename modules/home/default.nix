{ pkgs, osConfig, ... }:
{
  imports = [
    ./browser.nix
    ./niri.nix
    ./quickshell.nix
    ./foot.nix
    ./fish.nix
    ./gtk.nix
    ./zed.nix
    ./qt.nix
    ./thunar.nix
  ];

  home.username = "ruggy";
  home.homeDirectory = "/home/ruggy";

  home.packages = with pkgs; [
    # Session tools the niri config and Tessera call
    swayidle
    playerctl
    wl-clipboard
    xwayland-satellite
    xdg-utils
    ripgrep
    wtype # Tessera's clipboard copy & paste
    pavucontrol
    bluetui
    qt6Packages.qt6ct

    # Apps and CLI
    fastfetch
    rustup
    orca-slicer
    nixd
    claude-code

    # Other random stuff
    discord
    prismlauncher
    btop
    peazip
  ];

  services.cliphist.enable = true;
  services.polkit-gnome.enable = true;

  programs.git = {
    enable = true;
    settings.user = {
      name = "ruggy@${osConfig.networking.hostName}";
      email = "mateusanselmoguarino@gmail.com";
    };
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;

    options = [ "--cmd cd" ];
  };

  home.stateVersion = "26.11";
}
