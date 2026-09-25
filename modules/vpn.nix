{ inputs, ... }:

# Windscribe desktop app (GUI), built from Windscribe's official source by
# https://github.com/Varmisanth/windscribe-nixos. Pinned in flake.lock; updates with `nix flake update`.
{
  imports = [ inputs.windscribe-nixos.nixosModules.windscribe ];

  programs.windscribe = {
    enable = true;
    users = [ "heath" ];
  };

  networking.firewall.checkReversePath = "loose"; # needed for WireGuard
}
