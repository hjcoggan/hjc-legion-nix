{ pkgs, lib, ... }:

# Login screen + the two environments you can pick from it:
#   1. Steam Big Picture in SteamOS mode (gamescope session): always the default
#   2. KDE Plasma Bigscreen
let
  # Big, touch-friendly login: the theme has an on-screen keyboard button and large controls.
  loginTheme = pkgs.sddm-astronaut.override {
    embeddedTheme = "astronaut";
    themeConfig = {
      ScreenWidth = "1920";
      ScreenHeight = "1200";
      FontSize = "20";
      KeyboardSize = "0.6"; # bigger on-screen keyboard for thumbs
      HideVirtualKeyboard = "false";
    };
  };
in
{
  # Plasma 6 provides the workspace Bigscreen is built on, and the Plasma touch keyboard
  # (plasma-keyboard). Its own desktop sessions are hidden below.
  services.desktopManager.plasma6.enable = true;

  services.displayManager = {
    defaultSession = "gamescope-wayland"; # Steam, always preselected

    # Only these two sessions appear on the login screen.
    sessionPackages = lib.mkForce [
      pkgs.gamescope-session # "gamescope-wayland": Steam in SteamOS mode
      pkgs.kdePackages.plasma-bigscreen # "plasma-bigscreen-wayland"
    ];

    # Jovian's autoStart (gaming.nix) would log straight into Steam. We want the login screen
    # at every boot, so turn the autologin off. Jovian's "Switch to Desktop" plumbing stays.
    autoLogin.enable = lib.mkForce false;

    sddm = {
      enable = true;
      theme = "sddm-astronaut-theme";
      extraPackages = [ loginTheme ];
      settings = {
        General.InputMethod = "qtvirtualkeyboard"; # on-screen keyboard on the login screen
        Users.RememberLastSession = false; # always start on Steam
      };
    };
  };

  environment.systemPackages = [
    loginTheme
    pkgs.kdePackages.plasma-bigscreen
  ];

  # The login screen and Plasma Bigscreen are Wayland/Qt; portals for file pickers etc.
  xdg.portal.enable = true;
}
