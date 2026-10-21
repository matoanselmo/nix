# Intel CPU + iGPU (Kaby Lake on the Surface Pro 5). Mesa covers OpenGL and
# Vulkan (ANV); intel-media-driver adds VA-API decode/encode.
{ pkgs, ... }:
{
  hardware.cpu.intel.updateMicrocode = true;

  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.intel-media-driver ];
  };
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  environment.systemPackages = with pkgs; [
    libva-utils
    vulkan-tools
  ];
}
