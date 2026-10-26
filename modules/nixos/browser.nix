# Which browser a host uses. modules/home/browser.nix reads it (through
# osConfig) to install that one, make it the default, and point the
# `browser` command (niri's Mod+E) at it.
{ lib, ... }:
{
  options.my.browser = lib.mkOption {
    type = lib.types.enum [
      "zen"
      "helium"
    ];
    default = "zen";
    description = ''
      The host's web browser: Zen (beta) from zen-browser-flake, or Helium
      from nix-flake-helium-browser.
    '';
  };
}
