{ pkgs, ... }:

{
  # ── Flatpak + Bazaar app store ──
  services.flatpak.enable = true;
  systemd.services.flatpak-add-flathub = {
    description = "Add the Flathub remote";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    serviceConfig.Type = "oneshot";
    script = "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo";
  };

  # ── AppImages: run them natively (binfmt) so Gear Lever and double-click both work ──
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # ── Media codecs & non-free firmware ──
  hardware.enableAllFirmware = true;
  environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = "/run/current-system/sw/lib/gstreamer-1.0";

  # ── VPN: Windscribe (no Linux package in nixpkgs/Flathub) ──
  # Download WireGuard or OpenVPN configs from windscribe.com → Config Generators,
  # then import them in the network settings (KDE or `nmcli connection import`).
  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];
  networking.firewall.checkReversePath = "loose"; # needed for WireGuard

  # ── Extra gaming tools (picked from Bazzite / Nobara) ──
  services.hardware.openrgb.enable = true;        # RGB control (Nobara)
  services.input-remapper.enable = true;          # remap mice/keyboards/pads (Bazzite)
  virtualisation.podman.enable = true;            # for distrobox (Bazzite)
  programs.obs-studio = {                         # recording/streaming (Nobara, Bazzite)
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [ obs-vkcapture obs-pipewire-audio-capture obs-vaapi ];
  };

  environment.systemPackages = with pkgs; [
    # App store / Flatpak management
    bazaar
    flatseal
    gearlever            # AppImage manager: integrates into app menu, handles updates

    # Browsers
    ungoogled-chromium

    # Utilities
    mediawriter          # Fedora Media Writer
    grim slurp satty     # screenshots in niri (niri's built-in Print key also works; Plasma has Spectacle)

    # Video
    celluloid            # fast, simple mpv-based player
    mpv

    # Codecs
    ffmpeg-full
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
    libva-utils

    # VPN
    wireguard-tools

    # Bazzite / Nobara extras
    protonplus           # Proton-GE/Wine-GE manager (Bazzite; alongside ProtonUp-Qt)
    lutris               # (Nobara, Bazzite)
    wineWowPackages.stagingFull
    winetricks
    vkbasalt             # post-processing (sharpening etc.)
    distrobox            # run other distros' packages (Bazzite)
    steam-rom-manager    # add emulators/ROMs to Steam (Bazzite)
  ];
}
