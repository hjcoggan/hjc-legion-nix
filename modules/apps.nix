{ pkgs, ... }:

{
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    opencode
    faugus-launcher
    protonup-qt
    heroic
  ];
}
