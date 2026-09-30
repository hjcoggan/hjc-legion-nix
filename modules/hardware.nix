{ pkgs, ... }:

# Lenovo Legion Go S: Ryzen Z2 Go (4x Zen 3+, 12 CU RDNA 2), 8" 1920x1200 120 Hz touchscreen,
# MediaTek Wi-Fi 7, built-in controllers with back buttons and gyro.
{
  # Newest kernel: the Legion Go / Go S HID drivers (controller settings, back buttons) were
  # merged for Linux 7.1, and RDNA 2 handheld fixes keep landing.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableAllFirmware = true; # Wi-Fi, Bluetooth and audio DSP firmware
  hardware.firmware = [ pkgs.sof-firmware ];

  hardware.amdgpu.initrd.enable = true; # native panel resolution from the first frame
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Battery, power profiles and firmware updates (Lenovo publishes BIOS updates through fwupd/LVFS)
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.fwupd.enable = true;

  # Controllers, gyro and back buttons are handled by InputPlumber (enabled by Jovian, gaming.nix),
  # the same stack SteamOS uses on this device. Don't add handheld-daemon (hhd) next to it:
  # two controller managers fight over the same devices.

  environment.systemPackages = with pkgs; [ vulkan-tools ];
}
