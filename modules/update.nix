{ config, lib, pkgs, ... }:

# One-tap system update, usable with the touchscreen in both environments:
#   - Steam (gamescope):  "Update System" appears in the Steam library as a non-Steam shortcut
#   - Plasma Bigscreen:   "Update System" is a normal app in the launcher
#
# What it does: pull the latest settings from GitHub, update package versions (nix flake update),
# build the new system and install it for the next boot (nixos-rebuild boot), then offer a restart.
# The actual work runs as the root service hjc-update.service; the user may start that one service
# (and nothing else) without a password. Progress is shown in a big zenity dialog.
let
  flakeDir = "/etc/nixos";
  logFile = "/var/log/hjc-update.log";
  user = "heath";

  # Apps to place in the Steam library (name -> command on PATH)
  steamShortcuts = [
    { name = "Update System"; exe = "/run/current-system/sw/bin/hjc-update"; }
    { name = "Firefox"; exe = "/run/current-system/sw/bin/firefox"; }
    { name = "Heroic Games Launcher"; exe = "/run/current-system/sw/bin/heroic"; }
    { name = "Lutris"; exe = "/run/current-system/sw/bin/lutris"; }
    { name = "Faugus Launcher"; exe = "/run/current-system/sw/bin/faugus-launcher"; }
    { name = "ProtonUp-Qt"; exe = "/run/current-system/sw/bin/protonup-qt"; }
  ];

  shortcutsJson = pkgs.writeText "steam-shortcuts.json" (builtins.toJSON steamShortcuts);
  python = pkgs.python3.withPackages (ps: [ ps.vdf ]);
  addSteamShortcuts = pkgs.writeShellScript "add-steam-shortcuts" ''
    exec ${python}/bin/python3 ${./steam-shortcuts.py} ${shortcutsJson}
  '';

  hjc-update = pkgs.writeShellScriptBin "hjc-update" ''
    export PATH=${lib.makeBinPath [ pkgs.zenity pkgs.coreutils config.systemd.package ]}:$PATH
    export GDK_DPI_SCALE=1.4 # bigger text on the 8-inch screen
    TITLE="Update System"
    LOG=${logFile}

    zenity --question --title="$TITLE" --width=760 \
      --ok-label="Update now" --cancel-label="Not now" \
      --text="<span size='x-large'><b>Update the system?</b></span>\n\nThis fetches the latest settings and packages and installs them for the next restart. It can take a while, so keep the charger plugged in." \
      || exit 0

    rcfile=$(mktemp)
    (
      systemctl start --wait hjc-update.service &
      pid=$!
      while kill -0 "$pid" 2>/dev/null; do
        line=$(tail -n 1 "$LOG" 2>/dev/null | cut -c1-100)
        [ -n "$line" ] && printf '# %s\n' "$line"
        sleep 1
      done
      wait "$pid"
      echo $? > "$rcfile"
    ) | zenity --progress --pulsate --no-cancel --auto-close --no-markup \
        --title="$TITLE" --width=760 --text="Starting..."

    rc=$(cat "$rcfile" 2>/dev/null)
    rm -f "$rcfile"

    if [ "$rc" = "0" ]; then
      zenity --question --title="$TITLE" --width=760 \
        --ok-label="Restart now" --cancel-label="Later" \
        --text="<span size='x-large'><b>Update ready</b></span>\n\nRestart to start using it." \
        && systemctl reboot
    else
      out=$(mktemp)
      tail -n 40 "$LOG" > "$out" 2>/dev/null
      zenity --text-info --title="Update failed" --width=900 --height=600 \
        --ok-label="Close" --filename="$out"
      rm -f "$out"
    fi
  '';

  desktopItem = pkgs.makeDesktopItem {
    name = "hjc-update";
    desktopName = "Update System";
    comment = "Fetch and install system updates";
    exec = "hjc-update";
    icon = "system-software-update";
    categories = [ "System" ];
  };
in
{
  environment.systemPackages = [ hjc-update desktopItem ];

  # The config lives in ${flakeDir}, owned by the user so the updater can git pull / update the lock.
  systemd.tmpfiles.rules = [ "Z ${flakeDir} - ${user} users - -" ];

  systemd.services.hjc-update = {
    description = "Fetch and install system updates";
    restartIfChanged = false;
    stopIfChanged = false;
    path = with pkgs; [
      config.nix.package
      git
      util-linux
      coreutils
      gnutar
      gzip
      xz
    ];
    serviceConfig = {
      Type = "oneshot";
      StandardOutput = "truncate:${logFile}";
      StandardError = "inherit";
      UMask = "0022";
    };
    script = ''
      cd ${flakeDir}
      as_user() { runuser -u ${user} -- env HOME=/home/${user} "$@"; }

      echo "Fetching the latest settings from GitHub..."
      # Drop local lock changes so the pull can't conflict (a lock git doesn't know yet is simply regenerated)
      as_user git checkout HEAD -- flake.lock 2>/dev/null || rm -f flake.lock
      as_user git pull --ff-only || echo "Could not reach GitHub; using the settings already on this device."

      echo "Checking for newer packages..."
      as_user nix flake update || echo "Could not check for newer packages; keeping the current versions."
      as_user git add -A || true # flakes only see files git knows about

      echo "Building the update (this is the long part)..."
      ${config.system.build.nixos-rebuild}/bin/nixos-rebuild boot --flake ${flakeDir}#legion-go-s

      echo "Done."
    '';
  };

  # Let the user start this one service without a password prompt (Gaming Mode has no
  # polkit agent to show one).
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "hjc-update.service" &&
          subject.user == "${user}" && subject.local && subject.active) {
        return polkit.Result.YES;
      }
    });
  '';

  # Put the shortcuts in the Steam library right before Steam starts (Gaming Mode).
  # Shows up after you have signed in to Steam once and the session restarts.
  systemd.user.services.gamescope-session.serviceConfig.ExecStartPre = [ "-${addSteamShortcuts}" ];
}
