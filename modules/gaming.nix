{ pkgs, ... }:

let
  # Big Picture's "Switch to Desktop" runs `steamos-session-select`. NixOS doesn't ship it, so
  # Steam just restarts in a loop. This version shuts Steam down and ends the session, which
  # drops you back at the login screen to pick Niri or Plasma.
  # Steam runs this inside its bubblewrap sandbox, where loginctl stalls. So it only asks the
  # (unsandboxed) systemd user manager to end the session via steam-exit-to-login@<id>.
  # Logs to ~/.cache/steamos-session-select.log for troubleshooting.
  steamos-session-select = pkgs.writeShellScriptBin "steamos-session-select" ''
    unset LD_PRELOAD
    log="$HOME/.cache/steamos-session-select.log"
    echo "$(date) called with: $* (XDG_SESSION_ID=''${XDG_SESSION_ID:-unset})" >> "$log"
    ${pkgs.systemd}/bin/systemctl --user start --no-block "steam-exit-to-login@''${XDG_SESSION_ID}.service" >> "$log" 2>&1 \
      && echo "requested logout" >> "$log" \
      || echo "systemctl --user failed" >> "$log"
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

  # Runs outside Steam's sandbox. Graceful first: Steam shuts down, gamescope exits on its own
  # and the session ends like a normal logout. Force-killing everything at once raced SDDM's
  # greeter for the display (black screen with a cursor), so terminate-session is only a fallback.
  systemd.user.services."steam-exit-to-login@" = {
    description = "End Steam Big Picture session %i and return to the login screen";
    path = [ pkgs.procps pkgs.systemd "/run/current-system/sw" ];
    script = ''
      steam -shutdown || true
      for _ in $(seq 20); do
        pgrep -u "$(id -u)" -f gamescope >/dev/null || exit 0
        sleep 1
      done
      echo "Steam did not exit in 20s; ending session $1"
      loginctl --no-ask-password terminate-session "$1"
    '';
    scriptArgs = "%i";
    serviceConfig.Type = "oneshot";
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
