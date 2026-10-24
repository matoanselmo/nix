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
    ripgrep # Tessera's `/` file search
    pavucontrol
    bluetui
    qt6Packages.qt6ct

    # The niri config spawns `zed`; nixpkgs names the binary `zeditor`.
    zed-editor
    (writeShellScriptBin "zed" ''exec ${zed-editor}/bin/zeditor "$@"'')

    # Apps and CLI
    fastfetch
    rustup
    orca-slicer
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
