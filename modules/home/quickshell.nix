# Tessera (github:matoanselmo/tessera) as ~/.config/quickshell, run by
# upstream Quickshell.
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # NixOS keeps PAM services in /etc/pam.d, not /usr/lib/pam.d.
  tessera = pkgs.runCommand "tessera-config" { } ''
    cp -r ${inputs.tessera} $out
    chmod -R u+w $out
    substituteInPlace $out/ShellGlobals.qml \
      --replace-fail '"/usr/lib/pam.d"' '"/etc/pam.d"'
  '';

  # Tessera imports Qt5Compat.GraphicalEffects, which nixpkgs' quickshell
  # isn't built with. Add it to the QML import path instead of rebuilding.
  quickshell = pkgs.symlinkJoin {
    name = "quickshell-with-qt5compat";
    paths = [ pkgs.quickshell ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in $out/bin/*; do
        wrapProgram "$bin" \
          --prefix QML_IMPORT_PATH : ${pkgs.qt6.qt5compat}/${pkgs.qt6.qtbase.qtQmlPrefix}
      done
    '';
  };
in
{
  programs.quickshell = {
    enable = true;
    package = quickshell;
  };

  xdg.configFile."quickshell".source = tessera;

  # Wallpapers for the @config picker. settings.json is written by Tessera
  # itself, so it's only seeded when missing, never managed.
  xdg.configFile."tessera/backgrounds/default.png".source = ./files/tessera/default.png;
  home.activation.seedTesseraSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.config/tessera/settings.json"
    if [ ! -e "$settings" ]; then
      run install -Dm644 ${./files/tessera/settings.json} "$settings"
    fi
  '';
}
