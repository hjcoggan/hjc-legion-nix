{ pkgs, ... }:

let
  # Big Picture's "Switch to Desktop" runs `steamos-session-select`. NixOS doesn't ship it, so
  # Steam just restarts in a loop. This version shuts Steam down and ends the session, which
  # drops you back at the login screen to pick Niri or Plasma.
  steamos-session-select = pkgs.writeShellScriptBin "steamos-session-select" ''
    steam -shutdown || true
    sleep 3
    ${pkgs.systemd}/bin/loginctl terminate-session "''${XDG_SESSION_ID:-self}"
  '';
in
# Aim: SteamOS-like experience. You also get a "Steam Big Picture (gamescope)" session at the login screen.
{
  programs.steam = {
    enable = true;
    gamescopeSession = {
      enable = true;                      # SteamOS-style session selectable at login
      # SteamOS mode (as on the Deck): the only mode where "Switch to Desktop" calls
      # steamos-session-select. Plain -tenfoot ignores it and just restarts Steam.
      steamArgs = [ "-gamepadui" "-steamos3" "-pipewire-dmabuf" ];
    };
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    dedicatedServer.openFirewall = true;
    protontricks.enable = true;
    extest.enable = true;                 # Steam Input for controllers under Wayland
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    extraPackages = [ steamos-session-select ]; # visible inside Steam's FHS environment
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
