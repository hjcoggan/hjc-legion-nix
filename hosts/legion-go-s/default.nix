{ ... }:

{
  imports = [
    # Generated on the Go S during install:
    #   nixos-generate-config --show-hardware-config > hosts/legion-go-s/hardware-configuration.nix
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/hardware.nix
    ../../modules/desktop.nix
    ../../modules/gaming.nix
    ../../modules/apps.nix
    ../../modules/update.nix
  ];

  networking.hostName = "legion-go-s";

  users.users.heath = {
    isNormalUser = true;
    description = "Heath";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
  };

  # btrfs subvolumes (@, @home, @nix, @log). These options merge with hardware-configuration.nix.
  fileSystems = {
    "/".options = [ "compress=zstd:1" "noatime" ];
    "/home".options = [ "compress=zstd:1" "noatime" ];
    "/nix".options = [ "compress=zstd:1" "noatime" ];
    "/var/log".options = [ "compress=zstd:1" "noatime" ];
  };
  services.btrfs.autoScrub.enable = true;

  system.stateVersion = "26.05"; # Set once at install; don't change later.
}
