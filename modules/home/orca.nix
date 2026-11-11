{ pkgs, ... }:
{
  # Orca Slicer with the Mimi3D vendor profile (the printer: Klipper bed slinger
  # on matoserver) baked into its system profiles. files/orca holds the vendor
  # index (Mimi3D.json) and its Mimi3D/ folder; bump "version" in Mimi3D.json on
  # every change so Orca reloads it. Overriding postInstall means Orca builds
  # from source instead of coming from the binary cache.
  home.packages = [
    (pkgs.orca-slicer.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        cp -r ${./files/orca}/. $out/resources/profiles/
      '';
    }))
  ];
}
