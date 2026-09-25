{ ... }:

{
  home.username = "heath";
  home.homeDirectory = "/home/heath";

  # Niri config adapted from https://github.com/CachyOS/cachyos-niri-settings
  xdg.configFile."niri".source = ./niri;

  # Automount removable drives in niri (Plasma does this on its own)
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
  };

  home.stateVersion = "25.11";
}
