# The niri config stays a plain KDL file (Tessera's keybinds overlay parses
# it). niri itself comes from programs.niri in modules/nixos/desktop.nix.
{
  xdg.configFile."niri/config.kdl".source = ./files/niri/config.kdl;
}
