{ pkgs, lib, ... }:

# Boots into a touch-friendly session picker (no login screen, no password): Steam, Plasma or
# Plasma Bigscreen. SDDM auto logs in to the picker session; tapping a choice makes the picker
# session itself become the chosen session (it execs it), so no sudo or SDDM restart is involved.
# Jovian's autoStart (gaming.nix) still handles the Steam session and the in-Steam
# "Switch to Desktop" (regular Plasma) / "Return to Gaming Mode" switching.
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

  # Plasma Bigscreen session with absolute store paths. If Bigscreen dies within 20 seconds it
  # falls back to regular Plasma.
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

  # The picker UI: three big touch buttons in a kiosk compositor (cage). It only records which
  # button was pressed (yad's exit code); the outer script acts on it once cage has exited.
  pickerInner = pkgs.writeShellScript "hjc-session-picker-inner" ''
    export XDG_CONFIG_HOME=$(mktemp -d)
    mkdir -p $XDG_CONFIG_HOME/gtk-3.0
    cat > $XDG_CONFIG_HOME/gtk-3.0/gtk.css <<'CSS'
    * { font-size: 34px; }
    button { padding: 48px 24px; min-height: 120px; border-radius: 24px; }
    CSS
    ${pkgs.yad}/bin/yad --title="Session" --fullscreen --undecorated --no-escape \
      --text-align=center --buttons-layout=spread \
      --text='<span size="xx-large">What do you want to launch?</span>' \
      --button="Steam:10" --button="Plasma Desktop:11" --button="Plasma Bigscreen:12"
    echo $? > "$XDG_RUNTIME_DIR/hjc-choice"
  '';

  pickerScript = pkgs.writeShellScript "hjc-session-picker" ''
    rm -f "$XDG_RUNTIME_DIR/hjc-choice"
    ${pkgs.cage}/bin/cage -ds -- ${pickerInner}
    choice=$(cat "$XDG_RUNTIME_DIR/hjc-choice" 2>/dev/null || echo 10)
    rm -f "$XDG_RUNTIME_DIR/hjc-choice"

    case "$choice" in
      11) exec ${workspace}/libexec/plasma-dbus-run-session-if-needed ${workspace}/bin/startplasma-wayland ;;
      12) exec ${bigscreenSessionScript} ;;
    esac

    # Steam: run the same command SDDM would run for the Steam session.
    d=/run/current-system/sw/share/wayland-sessions/gamescope-wayland.desktop
    if [ -r "$d" ]; then
      cmd=$(${pkgs.gnused}/bin/sed -n 's/^Exec=//p' "$d" | head -n1)
      [ -n "$cmd" ] && exec sh -c "$cmd"
    fi
    # Fallback: ask steamos-manager to switch (what "Return to Gaming Mode" does).
    [ -n "$DBUS_SESSION_BUS_ADDRESS" ] || export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
    exec ${pkgs.steamos-manager}/bin/steamosctl switch-to-game-mode
  '';

  mkSession = name: label: script: pkgs.runCommand "${name}-session"
    { passthru.providedSessions = [ name ]; }
    ''
      mkdir -p $out/share/wayland-sessions
      cat > $out/share/wayland-sessions/${name}.desktop <<EOF
      [Desktop Entry]
      Name=${label}
      Exec=${script}
      TryExec=${script}
      DesktopNames=KDE
      EOF
    '';
in
{
  # Plasma 6 provides regular Plasma (session "plasma") and the workspace Bigscreen is built on.
  services.desktopManager.plasma6.enable = true;

  services.displayManager.sessionPackages = [
    (mkSession "plasma-bigscreen-safe" "Plasma Bigscreen" bigscreenSessionScript)
    (mkSession "hjc-session-picker" "Session Picker" pickerScript)
  ];

  # Boot lands on the picker (Jovian sets this to Steam otherwise).
  services.displayManager.defaultSession = lib.mkForce "hjc-session-picker";

  environment.systemPackages = [
    bigscreen
    returnToGaming
  ];

  xdg.portal.enable = true;
}
