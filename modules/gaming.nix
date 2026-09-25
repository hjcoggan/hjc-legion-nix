{ pkgs, ... }:

# Aim: SteamOS-like experience. You also get a "Steam Big Picture (gamescope)" session at the login screen.
{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;       # SteamOS-style session selectable at login
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    dedicatedServer.openFirewall = true;
    protontricks.enable = true;
    extest.enable = true;                 # Steam Input for controllers under Wayland
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.gamemode = {
    enable = true;
    settings.general.renice = 10;
  };

  # ── Steam Controller (original + 2026 model), Deck, Index, and other pads ──
  hardware.steam-hardware.enable = true;  # Valve udev rules (Steam Controller, Index, Deck)
  hardware.uinput.enable = true;          # lets Steam Input create virtual gamepads
  services.udev.packages = [ pkgs.game-devices-udev-rules ]; # PS/Switch/8BitDo etc.
  hardware.xone.enable = true;            # Xbox wireless dongle
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # SteamOS-like sysctls
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
    "kernel.split_lock_mitigate" = 0;
  };

  environment.systemPackages = with pkgs; [ mangohud goverlay ];
}
