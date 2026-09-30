{ pkgs, inputs, ... }:

{
  # Makes pkgs.claude-code the one from sadjow/claude-code-nix instead of nixpkgs'
  nixpkgs.overlays = [ inputs.claude-code.overlays.default ];

  programs.firefox.enable = true;
  programs.partition-manager.enable = true; # KDE Partition Manager (+ its privileged helper)

  environment.systemPackages = with pkgs; [
    claude-code       # Claude Code (from claude-code-nix; log in with your Claude subscription)
    faugus-launcher
    protonup-qt
    heroic
    fastfetch
    gnome-text-editor # simple GUI text editor (Kate also comes with Plasma)
    rpi-imager        # Raspberry Pi Imager
  ];
}
