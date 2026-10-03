{ pkgs, lib, ... }:

# Boots into a touch-friendly session picker (no login screen, no password): Steam, Plasma or
# Plasma Bigscreen. SDDM auto logs in to the picker session; tapping a choice makes SDDM restart
# straight into that session. Jovian's autoStart (gaming.nix) still handles the Steam session and
# the in-Steam "Switch to Desktop" (regular Plasma) / "Return to Gaming Mode" switching.
let
  bigscreen = pkgs.kdePackages.plasma-bigscreen;
  workspace = pkgs.kdePackages.plasma-workspace;
  user = "heath";
  conf = "/etc/sddm.conf.d/zzt-hjc-session.conf";

  returnToGaming = pkgs.makeDesktopItem {
    name = "return-to-gaming-mode";
    desktopName = "Return to Gaming Mode";
    comment = "Switch back to Steam";
    exec = "${pkgs.steamos-manager}/bin/steamosctl switch-to-game-mode";
    icon = "steam";
    categories = [ "System" ];
  };

  # Runs as root (via sudo, no password). "clear" removes the one-shot choice; anything else is
  # written as SDDM's autologin session and SDDM is restarted into it.
  selectSession = pkgs.writeShellScriptBin "hjc-select-session" ''
    case "$1" in
      clear) rm -f ${conf}; exit 0 ;;
      gamescope-wayland|plasma|plasma-bigscreen-safe) ;;
      *) echo "unknown session: $1" >&2; exit 1 ;;
    esac
    mkdir -p /etc/sddm.conf.d
    printf '[Autologin]\nUser=${user}\nSession=%s.desktop\nRelogin=true\n' "$1" > ${conf}
    ${pkgs.systemd}/bin/systemctl --no-block restart display-manager.service
  '';
  select = "/run/current-system/sw/bin/hjc-select-session";

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

  # The picker UI: three big touch buttons in a kiosk compositor (cage).
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
    case $? in
      11) s=plasma ;;
      12) s=plasma-bigscreen-safe ;;
      *) s=gamescope-wayland ;;
    esac
    touch "$XDG_RUNTIME_DIR/hjc-picked"
    exec /run/wrappers/bin/sudo ${select} $s
  '';

  pickerScript = pkgs.writeShellScript "hjc-session-picker" ''
    rm -f "$XDG_RUNTIME_DIR/hjc-picked"
    ${pkgs.cage}/bin/cage -ds -- ${pickerInner}
    # Picker failed to start or was closed without a choice: fall back to Steam, never loop.
    [ -e "$XDG_RUNTIME_DIR/hjc-picked" ] || /run/wrappers/bin/sudo ${select} gamescope-wayland
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
    selectSession
  ];

  security.sudo.extraRules = [{
    users = [ user ];
    commands = [{ command = select; options = [ "NOPASSWD" ]; }];
  }];

  # The one-shot choice must never stick: clear it at boot and as soon as the chosen session is up.
  systemd.services.hjc-session-clear = {
    description = "Clear one-shot session choice";
    before = [ "display-manager.service" ];
    wantedBy = [ "display-manager.service" ];
    serviceConfig = { Type = "oneshot"; ExecStart = "${selectSession}/bin/hjc-select-session clear"; };
  };
  systemd.user.services.hjc-session-clear = {
    description = "Clear one-shot session choice";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = { Type = "oneshot"; ExecStart = "/run/wrappers/bin/sudo ${select} clear"; };
  };

  xdg.portal.enable = true;
}
