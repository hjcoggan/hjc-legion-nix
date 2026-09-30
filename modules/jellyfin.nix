{ ... }:

# Jellyfin media server. Web UI: http://gaming-pc.local:8096 (or http://<PC's IP>:8096).
# Libraries live on the external PSSD T7 drive, mounted at /mnt/PSSD-T7 (see samba.nix), and are
# added in Jellyfin's web UI (the NixOS module can't declare libraries). Suggested layout:
#   /mnt/PSSD-T7/Media/Movies   /mnt/PSSD-T7/Media/Shows   /mnt/PSSD-T7/Media/Music
# Jellyfin only needs to read the drive. Files written over Samba are world-readable, so the
# jellyfin user can see them without any extra permissions.
{
  services.jellyfin = {
    enable = true;
    openFirewall = true; # 8096 web, 8920 https, 1900/udp + 7359/udp client discovery

    # Transcode on the GPU instead of the CPU, via VAAPI (Mesa). These settings are only written
    # on Jellyfin's first start; after that, change them in Dashboard > Playback.
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128"; # check with `ls -l /dev/dri/by-path/` if transcoding fails
    };
    transcoding = {
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true;
        vp9 = true;
        av1 = true;
      };
      hardwareEncodingCodecs.hevc = true;
    };
  };

  # Permission to open the GPU's render node
  users.users.jellyfin.extraGroups = [ "render" "video" ];
}
