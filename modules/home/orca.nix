{ pkgs, ... }:
let
  pname = "orca-slicer";
  version = "2.5.1";
  src = pkgs.fetchurl {
    url = "https://github.com/OrcaSlicer/OrcaSlicer/releases/download/v${version}/OrcaSlicer_Linux_AppImage_Ubuntu2404_V${version}.AppImage";
    hash = "sha256-BzuBBckoNWFB2w3bzoi4HVLHqeJEL5uq4KkInIn/BOs=";
  };
  # Orca Slicer from the upstream AppImage, with the Mimi3D vendor profile (the
  # printer: Klipper bed slinger on matoserver) baked into its system profiles.
  # files/orca holds the vendor index (Mimi3D.json) and its Mimi3D/ folder; bump
  # "version" in Mimi3D.json on every change so Orca reloads it. Since 2.5 the
  # bundled vendors ship as compiled .opc caches, but a vendor with only JSON is
  # still parsed (and cached on first load). To update, bump version and hash.
  contents = pkgs.appimageTools.extract {
    inherit pname version src;
    postExtract = ''
      chmod -R u+w $out/resources/profiles
      cp -r ${./files/orca}/. $out/resources/profiles/
    '';
  };
in
{
  home.packages = [
    (pkgs.appimageTools.wrapAppImage {
      inherit pname version contents;
      # The AppImage expects WebKitGTK from the host.
      extraPkgs = pkgs: [ pkgs.webkitgtk_4_1 pkgs.libsoup_3 ];
      # Otherwise Orca guesses a Fedora CA path and asks about it on startup.
      profile = ''
        export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
        # WebKitGTK/libsoup (the login page) get TLS from glib-networking's GIO module.
        export GIO_EXTRA_MODULES=${pkgs.glib-networking}/lib/gio/modules
      '';
      extraInstallCommands = ''
        install -Dm444 ${contents}/usr/share/applications/com.orcaslicer.OrcaSlicer.desktop \
          $out/share/applications/com.orcaslicer.OrcaSlicer.desktop
        substituteInPlace $out/share/applications/com.orcaslicer.OrcaSlicer.desktop \
          --replace-fail 'Exec=AppRun' 'Exec=${pname}'
        cp -r ${contents}/usr/share/icons $out/share/
      '';
    })
  ];
}
