{ pkgs, ... }:

{
  programs.firefox.enable = true;
  # Smooth touch scrolling when Firefox runs under X11 (e.g. inside the Steam session)
  environment.sessionVariables.MOZ_USE_XINPUT2 = "1";

  environment.systemPackages = with pkgs; [
    heroic # Epic / GOG / Amazon games
    lutris # everything else (Battle.net, EA, emulators...)
    faugus-launcher # Proton launcher for non-Steam Windows games
    protonup-qt # install and update Proton-GE and Wine builds
    mangohud # FPS / battery overlay for games (Jovian's patched build)
  ];
}
