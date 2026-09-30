{ pkgs, ... }:

{
  imports = [
    # Generate on the PC: nixos-generate-config --show-hardware-config > hosts/gaming-pc/hardware-configuration.nix
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/amd.nix
    ../../modules/desktop.nix
    ../../modules/gaming.nix
    ../../modules/apps.nix
    ../../modules/software.nix
    ../../modules/vpn.nix
    ../../modules/samba.nix
    ../../modules/llm.nix
    ../../modules/jellyfin.nix
  ];

  # btrfs (subvolumes @, @home, @nix, @log). These options merge with hardware-configuration.nix.
  fileSystems = {
    "/".options = [ "compress=zstd" "noatime" ];
    "/home".options = [ "compress=zstd" "noatime" ];
    "/nix".options = [ "compress=zstd" "noatime" ];
    "/var/log".options = [ "compress=zstd" "noatime" ];
  };
  services.btrfs.autoScrub.enable = true;

  networking.hostName = "gaming-pc";
  time.timeZone = "America/New_York"; # TODO: change if needed

  users.users.heath = {
    isNormalUser = true;
    description = "Heath";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" "gamemode" ];
  };

  system.stateVersion = "25.11"; # Set once at install; don't change later.
}
