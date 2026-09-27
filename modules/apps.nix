{ pkgs, ... }:

{
  programs.firefox.enable = true;
  programs.partition-manager.enable = true; # KDE Partition Manager (+ its privileged helper)

  environment.systemPackages = with pkgs; [
    claude-code       # Claude Code (uses your Claude subscription: run `claude` and log in)
    faugus-launcher
    protonup-qt
    heroic
    fastfetch
    gnome-text-editor # simple GUI text editor (Kate also comes with Plasma)
    rpi-imager        # Raspberry Pi Imager
  ];
}
