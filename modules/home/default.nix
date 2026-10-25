{ pkgs, ... }:
{
  imports = [
    ./browser.nix
    ./niri.nix
    ./quickshell.nix
    ./foot.nix
    ./fish.nix
    ./gtk.nix
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
    grim # Tessera's screenshot tile
    slurp
    pavucontrol
    bluetui
    qt6Packages.qt6ct
    zed-editor

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
  ];

  services.cliphist.enable = true;
  services.polkit-gnome.enable = true;

  programs.git.enable = true;

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;

    options = [ "--cmd cd" ];
  };

  home.stateVersion = "26.11";
}
