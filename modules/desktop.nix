{ pkgs, ... }:

# Boots straight into Steam (SteamOS mode), with no login screen or password: this device stays
# at home. Jovian's autoStart (gaming.nix) does the auto login and the session switching:
#   - "Switch to Desktop" in Steam's power menu opens Plasma Bigscreen.
#   - "Return to Gaming Mode" (an app in Bigscreen), or logging out of Bigscreen, brings Steam back.
let
  returnToGaming = pkgs.makeDesktopItem {
    name = "return-to-gaming-mode";
    desktopName = "Return to Gaming Mode";
    comment = "Switch back to Steam";
    exec = "${pkgs.steamos-manager}/bin/steamosctl switch-to-game-mode";
    icon = "steam";
    categories = [ "System" ];
  };
in
{
  # Plasma 6 provides the workspace Bigscreen is built on, plus the Plasma touch keyboard.
  services.desktopManager.plasma6.enable = true;

  # Registers the "plasma-bigscreen-wayland" session (the desktopSession named in gaming.nix).
  services.displayManager.sessionPackages = [ pkgs.kdePackages.plasma-bigscreen ];

  environment.systemPackages = [
    pkgs.kdePackages.plasma-bigscreen
    returnToGaming
  ];

  xdg.portal.enable = true;
}
