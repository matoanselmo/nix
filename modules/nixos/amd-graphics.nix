# AMD CPU + GPU. Mesa (via hardware.graphics) provides radeonsi for OpenGL,
# RADV for Vulkan and the radeonsi VA-API driver for hardware video decode.
{ pkgs, ... }:
{
  boot.initrd.kernelModules = [ "amdgpu" ];
  
  hardware.cpu.amd.updateMicrocode = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam/Proton and other 32-bit games
  };
  hardware.amdgpu.initrd.enable = true;

  environment.systemPackages = with pkgs; [
    libva-utils # vainfo
    vulkan-tools # vulkaninfo
    mesa-demos # glxinfo
  ];
}
