{ ... }:

{
  # Fixed mount point so the share path doesn't depend on udisks auto-mounting.
  fileSystems."/mnt/PSSD-T7" = {
    device = "/dev/disk/by-uuid/129f2eb8-ce11-4879-aed8-3f7babdb33d5";
    fsType = "ext4";
    options = [ "nofail" "noatime" "x-systemd.device-timeout=5s" "x-systemd.automount" ];
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "server string" = "gaming-pc";
        "security" = "user";
        "map to guest" = "never";
        # macOS compatibility (Finder metadata, resource forks, Time Machine-style naming)
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
      };
      "PSSD T7" = {
        "path" = "/mnt/PSSD-T7";
        "valid users" = "heath";
        "force user" = "heath";
        "read only" = "no";
        "browseable" = "yes";
      };
    };
  };

  # Bonjour, so the share shows up in Finder's sidebar.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };
}
