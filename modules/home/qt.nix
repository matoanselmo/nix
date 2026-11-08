{ pkgs, ... }:
{
  # niri's environment block sets QT_QPA_PLATFORMTHEME=qt6ct, so the platform
  # theme isn't set here; this only writes qt6ct's config. Fusion with qt6ct's
  # "darker" palette stands in for Adwaita-dark (adwaita-qt is unmaintained).
  qt = {
    enable = true;
    qt6ctSettings.Appearance = {
      style = "Fusion";
      custom_palette = true;
      color_scheme_path = "${pkgs.qt6Packages.qt6ct}/share/qt6ct/colors/darker.conf";
      icon_theme = "Adwaita";
      standard_dialogs = "default";
    };
  };
}
