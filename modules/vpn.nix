{ inputs, ... }:

# Windscribe desktop app (GUI), built from Windscribe's official source by
# https://github.com/Varmisanth/windscribe-nixos. Pinned in flake.lock; updates with `nix flake update`.
{
  imports = [ inputs.windscribe-nixos.nixosModules.windscribe ];

  # Pre-built Windscribe from the maintainer's cache (skips the long source build)
  nix.settings = {
    substituters = [ "https://varmisanth.cachix.org" ];
    trusted-public-keys = [ "varmisanth.cachix.org-1:rt04yjDDJKDWe+h6B1XQWfdsSDUX6uks+9IKVBjn2d8=" ];
  };

  programs.windscribe = {
    enable = true;
    users = [ "heath" ];
  };

  networking.firewall.checkReversePath = "loose"; # needed for WireGuard
}
