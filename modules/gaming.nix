{ pkgs, ... }:

# SteamOS-like gaming via Jovian-NixOS (https://jovian-experiments.github.io/Jovian-NixOS/),
# which recreates the Steam Deck software stack on generic hardware. The Legion Go S is not a
# Deck, so no jovian.devices.steamdeck options are used.
{
  jovian.steam = {
    enable = true;
    # Boot straight into Steam (automatic login, no password) and enable Jovian's session
    # switching ("Switch to Desktop" inside Steam).
    autoStart = true;
    user = "heath";
    # "Switch to Desktop" in Steam's power menu opens Plasma Bigscreen.
    desktopSession = "plasma-bigscreen-wayland";
  };

  # Jovian's SD card rules are for the Deck. udiskie (below) mounts every removable drive the
  # same way in both environments.
  jovian.steamos.enableAutoMountUdevRules = false;

  programs.steam = {
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    protontricks.enable = true;
  };

  programs.gamemode.enable = true;

  # Automount SD cards and USB drives, in the Steam session and in Plasma Bigscreen.
  services.udisks2.enable = true;
  systemd.user.services.udiskie = {
    description = "Automount removable drives";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.udiskie}/bin/udiskie --automount --no-notify --no-tray";
      Restart = "on-failure";
    };
  };
}
