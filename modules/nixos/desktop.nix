# The graphical session: niri, greetd + tuigreet, and what Tessera and the
# niri config expect to find on the system.
{ pkgs, ... }:
{
  # Also sets up xdg-desktop-portal (gnome + gtk, the same preferences as the
  # old niri-portals.conf) and gnome-keyring.
  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
      user = "greeter";
    };
  };

  # Tessera's lock screen authenticates against swaylock's PAM service.
  security.pam.services.swaylock = { };

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-volman
      thunar-archive-plugin
    ];
  };
  programs.xfconf.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # NetworkManager and BlueZ already come from base.nix; Tessera's panels
  # talk to them directly.
  services.upower.enable = true;

  fonts.packages = with pkgs; [
    adwaita-fonts
    jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];
}
