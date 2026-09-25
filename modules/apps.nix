{ pkgs, ... }:

{
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    opencode
    faugus-launcher
    protonup-qt
    heroic
    fastfetch
    gnome-text-editor # simple GUI text editor (Kate also comes with Plasma)
  ];
}
