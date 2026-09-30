{ pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "@wheel" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";
  # A handheld travels: set the timezone from the current location instead of hard-coding one.
  services.automatic-timezoned.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  services.fstrim.enable = true;

  # Read/write the file systems removable drives usually use
  boot.supportedFilesystems = [ "ntfs" "exfat" "btrfs" ];

  # Git is used by the on-device updater. Credentials are stored per user (~/.git-credentials).
  programs.git = {
    enable = true;
    config = {
      safe.directory = "/etc/nixos";
      credential.helper = "store";
    };
  };

  environment.systemPackages = with pkgs; [ vim curl htop pciutils usbutils ];

  fonts.packages = with pkgs; [ noto-fonts noto-fonts-color-emoji inter ];
}
