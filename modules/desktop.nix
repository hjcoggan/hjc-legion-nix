{ pkgs, ... }:

# Boots straight into Steam (SteamOS mode), with no login screen or password: this device stays
# at home. Jovian's autoStart (gaming.nix) does the auto login and the session switching:
#   - "Switch to Desktop" in Steam's power menu opens Plasma Bigscreen.
#   - "Return to Gaming Mode" (an app in Bigscreen), or logging out of Bigscreen, brings Steam back.
let
  bigscreen = pkgs.kdePackages.plasma-bigscreen;
  workspace = pkgs.kdePackages.plasma-workspace;

  returnToGaming = pkgs.makeDesktopItem {
    name = "return-to-gaming-mode";
    desktopName = "Return to Gaming Mode";
    comment = "Switch back to Steam";
    exec = "${pkgs.steamos-manager}/bin/steamosctl switch-to-game-mode";
    icon = "steam";
    categories = [ "System" ];
  };

  # Session used by "Switch to Desktop". It starts Plasma Bigscreen with absolute store paths (no
  # reliance on PATH inside the SDDM session) and, if Bigscreen dies within 20 seconds, falls back
  # to regular Plasma so the switch never hangs on a dead session.
  bigscreenSessionScript = pkgs.writeShellScript "plasma-bigscreen-safe" ''
    export PATH=${bigscreen}/bin:${workspace}/bin:$PATH
    start=$(date +%s)
    ${workspace}/libexec/plasma-dbus-run-session-if-needed ${bigscreen}/bin/plasma-bigscreen-wayland
    rc=$?
    if [ "$rc" -ne 0 ] && [ $(( $(date +%s) - start )) -lt 20 ]; then
      echo "Plasma Bigscreen exited with $rc; falling back to Plasma" | ${pkgs.systemd}/bin/systemd-cat -t bigscreen-session -p err
      exec ${workspace}/libexec/plasma-dbus-run-session-if-needed ${workspace}/bin/startplasma-wayland
    fi
    exit $rc
  '';

  bigscreenSession = pkgs.runCommand "plasma-bigscreen-safe-session"
    { passthru.providedSessions = [ "plasma-bigscreen-safe" ]; }
    ''
      mkdir -p $out/share/wayland-sessions
      cat > $out/share/wayland-sessions/plasma-bigscreen-safe.desktop <<EOF
      [Desktop Entry]
      Name=Plasma Bigscreen
      Comment=Plasma Bigscreen (falls back to Plasma if it fails to start)
      Exec=${bigscreenSessionScript}
      TryExec=${bigscreenSessionScript}
      DesktopNames=KDE
      EOF
    '';
in
{
  # Plasma 6 provides the workspace Bigscreen is built on, plus the Plasma touch keyboard.
  services.desktopManager.plasma6.enable = true;

  # Registers the "plasma-bigscreen-safe" session (the desktopSession named in gaming.nix).
  services.displayManager.sessionPackages = [ bigscreenSession ];

  environment.systemPackages = [
    bigscreen
    returnToGaming
  ];

  xdg.portal.enable = true;
}
