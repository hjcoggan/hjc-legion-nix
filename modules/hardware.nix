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

  # Jovian: early amdgpu modesetting (native panel resolution from the first frame) and
  # write access to the backlight, which is what makes Steam's brightness slider work.
  jovian.hardware.has.amd.gpu = true;
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

  # Controllers, gyro and back buttons:
  # InputPlumber (enabled by Jovian) provides the SteamOS-compatible composite controller.
  # We install its udev rules, configure uinput access, and add the Legion Go S xpad/XInput handshake.
  hardware.uinput.enable = true;

  services.udev.packages = [
    pkgs.inputplumber
    pkgs.kdePackages.plasma-bigscreen
  ];

  services.udev.extraRules = ''
    # Lenovo Legion Go S (1a86:e310 / 1a86:e311) controller handshake
    # Bind xpad fallback for Legion Go S so it exposes a standard Xbox controller to SDL/evdev
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="e31[01]", RUN+="${pkgs.kmod}/bin/modprobe xpad", RUN+="${pkgs.bash}/bin/sh -c 'echo 1a86 $attr{idProduct} > /sys/bus/usb/drivers/xpad/new_id 2>/dev/null || true'"

    # Switch gamepad mode to xinput on device add/change
    ACTION=="add|change|bind", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="e31[01]", SUBSYSTEM=="hid", ATTR{gamepad/mode}="xinput", ATTR{os_mode}="linux"

    # User access for hidraw, uinput, and input event nodes
    KERNEL=="hidraw*", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="e31[01]", MODE="0660", TAG+="uaccess"
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", TAG+="uaccess", OPTIONS+="static_node=uinput"
    SUBSYSTEM=="input", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="e31[01]", TAG+="uaccess"
  '';

  environment.systemPackages = with pkgs; [
    vulkan-tools
    evtest
  ];
}
