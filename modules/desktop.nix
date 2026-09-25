{ pkgs, inputs, ... }:

let
  # Minimal login: black screen, a password field, and the session name underneath.
  # The session name under the password field switches Niri / Plasma / Steam Big Picture (F1 shows help).
  loginTheme = pkgs.where-is-my-sddm-theme.override {
    themeConfig.General = {
      backgroundFill = "#000000";
      basicTextColor = "#e6e6e6";
      font = "JetBrainsMono Nerd Font";
      helpFont = "JetBrainsMono Nerd Font";
      helpFontSize = 12;
      passwordFontSize = 28;
      passwordInputWidth = 0.25;
      passwordInputRadius = 8;
      passwordCursorColor = "#e6e6e6";
      passwordCharacter = "•";
      showSessionsByDefault = true;
      sessionsFontSize = 14;
      showUsersByDefault = false;
    };
  };
in
{
  imports = [ inputs.noctalia.nixosModules.default ];

  services.displayManager = {
    defaultSession = "niri";
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "where_is_my_sddm_theme";
      extraPackages = [ loginTheme ];
      # Always preselect Niri (defaultSession) instead of whatever was used last, e.g. Big Picture
      settings.Users.RememberLastSession = false;
    };
  };
  environment.systemPackages = [ loginTheme ] ++ (with pkgs; [
    xwayland-satellite # X11 apps (Steam!) under niri — niri starts it automatically
    alacritty          # niri terminal (MOD+Enter)
    nautilus           # niri file manager (MOD+E)
    udiskie            # automount under niri
    wl-clipboard
    kdePackages.qtstyleplugin-kvantum
  ]);

  # ── Niri (primary) ──
  programs.niri.enable = true;

  # ── Noctalia shell for niri ──
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  # ── KDE Plasma 6 (backup session) ──
  services.desktopManager.plasma6.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome pkgs.xdg-desktop-portal-gtk ];
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
