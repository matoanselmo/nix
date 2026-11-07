# Workstations only (desktop and laptop); the server imports core.nix alone
# (see mkHost in flake.nix). Hardware-specific modules (amd-graphics,
# intel-graphics, laptop-power) are imported from hosts/*.
{
  imports = [
    ./base.nix
    ./browser.nix
    ./desktop.nix
    ./nas.nix
  ];
}
