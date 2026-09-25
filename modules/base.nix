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
  boot.kernelPackages = pkgs.linuxPackages_latest; # newest kernel = best RDNA4 support

  networking.networkmanager.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  security.rtkit.enable = true;

  # zram as CachyOS does it (zram-generator: size = RAM, zstd) + cachyos-settings sysctls
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    priority = 100;
  };
  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
    "vm.page-cluster" = 0;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
  };
  services.fstrim.enable = true;
  services.fwupd.enable = true;

  # ── Automount drives like a normal desktop ──
  # udisks2 does the mounting; KDE uses it natively, and niri runs udiskie (see home/).
  services.udisks2.enable = true;
  services.gvfs.enable = true; # trash, MTP phones, network shares in file managers
  services.devmon.enable = false; # udiskie handles it per-user instead
  boot.supportedFilesystems = [ "ntfs" "exfat" "btrfs" ];

  environment.systemPackages = with pkgs; [
    git vim wget curl htop btop pciutils usbutils unzip
  ];

  fonts.packages = with pkgs; [
    noto-fonts noto-fonts-color-emoji nerd-fonts.jetbrains-mono inter
  ];
}
