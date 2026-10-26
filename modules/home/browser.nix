# The host's browser, picked by my.browser (modules/nixos/browser.nix):
#
# - Zen Browser (beta) from github:0xc000022070/zen-browser-flake. The binary
#   and desktop entry are `zen-beta`.
# - Helium from github:oxcl/nix-flake-helium-browser. The binary is `helium`,
#   the desktop entry `helium.desktop`.
#
# Both modules are always imported (imports can't depend on config); only
# the chosen one is enabled. Either way the chosen browser becomes the
# default, and `browser` runs it, which is what niri's Mod+E spawns.
{
  inputs,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  helium = osConfig.my.browser == "helium";
in
{
  imports = [
    inputs.zen-browser.homeModules.beta
    inputs.helium.homeModules.default
  ];

  programs.zen-browser = {
    enable = !helium;
    setAsDefaultBrowser = !helium;
  };

  programs.helium = {
    enable = helium;
    # Its wrapper only picks Wayland when NIXOS_OZONE_WL is set; ask directly.
    flags = [ "--ozone-platform-hint=auto" ];
  };

  # Helium's module has no setAsDefaultBrowser, so set the handlers here.
  xdg.mimeApps.defaultApplications = lib.mkIf helium (
    lib.genAttrs [
      "text/html"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/about"
      "x-scheme-handler/unknown"
    ] (_: "helium.desktop")
  );

  home.packages = [
    (pkgs.writeShellScriptBin "browser" ''exec ${if helium then "helium" else "zen-beta"} "$@"'')
  ];

  # setAsDefaultBrowser fills in xdg.mimeApps but doesn't turn it on.
  xdg.mimeApps.enable = true;
}
