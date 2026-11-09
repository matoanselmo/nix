{ pkgs, ... }:
{
  gtk = {
    enable = true;
    theme.name = "Adwaita";
    colorScheme = "dark";
  };

  # Matches the niri config's cursor block.
  home.pointerCursor = {
    enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 8;
    gtk.enable = true;
  };
}
