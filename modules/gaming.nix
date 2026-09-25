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

  hardware.steam-hardware.enable = true;  # Steam Controller / Index / Deck udev rules
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
