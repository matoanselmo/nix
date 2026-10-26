# Shared by every host. Hardware-specific modules (amd-graphics,
# intel-graphics, laptop-power) are imported from hosts/*.
{
  imports = [
    ./base.nix
    ./browser.nix
    ./desktop.nix
    ./disk.nix
    ./nas.nix
  ];
}
