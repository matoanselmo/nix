# Embedded dev: STM32F411 (ST-Link / CMSIS-DAP) and RP2040 (Picoprobe / BOOTSEL).
# Rust targets come from rustup: `rustup target add thumbv7em-none-eabihf thumbv6m-none-eabi`.
{ pkgs, ... }:
let
  tools = with pkgs; [
    probe-rs-tools
    openocd
    stlink
    picotool
    gcc-arm-embedded
    elf2uf2-rs
    flip-link
    dfu-util
  ];
in
{
  environment.systemPackages = tools;

  # Device access rules for the probes and the RP2040 boot ROM.
  services.udev.packages = [ pkgs.probe-rs-tools pkgs.openocd pkgs.stlink pkgs.picotool ];

  # Some of those rules use GROUP="plugdev"; NixOS doesn't create it by default.
  users.groups.plugdev = { };

  services.udev.extraRules = ''
    # Raspberry Pi debugprobe (CMSIS-DAP)
    ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000c", MODE="0660", GROUP="plugdev"
    # STM32 DFU bootloader
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0660", GROUP="plugdev"
  '';
}
