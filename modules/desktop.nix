{ pkgs, inputs, ... }:

let
  loginTheme = pkgs.sddm-astronaut.override {
    embeddedTheme = "purple_leaves"; # other options: astronaut, black_hole, cyberpunk, jake_the_dog, japanese_aesthetic, pixel_sakura, ...
  };
in
{
  imports = [ inputs.noctalia.nixosModules.default ];

  # ── Login screen: SDDM + Astronaut theme. Pick "Niri" or "Plasma (Wayland)" from the session menu. ──
  services.displayManager = {
    defaultSession = "niri";
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "sddm-astronaut-theme";
      extraPackages = [ loginTheme ];
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
