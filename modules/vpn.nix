{ inputs, lib, pkgs, ... }:

# Windscribe desktop app (GUI), built from Windscribe's official source by
# https://github.com/Varmisanth/windscribe-nixos. Pinned in flake.lock; updates with `nix flake update`.
{
  imports = [ inputs.windscribe-nixos.nixosModules.windscribe ];

  # Pre-built Windscribe from the maintainer's cache (skips the long source build)
  nix.settings = {
    substituters = [ "https://varmisanth.cachix.org" ];
    trusted-public-keys = [ "varmisanth.cachix.org-1:rt04yjDDJKDWe+h6B1XQWfdsSDUX6uks+9IKVBjn2d8=" ];
  };

  # Their module builds Windscribe against *our* nixpkgs, which would rebuild it on every
  # system update. Use their own package instead (their nixpkgs pin = what the cache has).
  nixpkgs.overlays = lib.mkAfter [
    (final: prev: { windscribe = inputs.windscribe-nixos.packages.${prev.stdenv.hostPlatform.system}.windscribe; })
  ];

  programs.windscribe = {
    enable = true;
    users = [ "heath" ];
  };

  networking.firewall.checkReversePath = "loose"; # needed for WireGuard

  # Windscribe sets tunnel DNS through systemd-resolved (resolvectl). Without it every
  # connection fails with "Could not activate remote peer org.freedesktop.resolve1".
  # NetworkManager switches to resolved automatically when this is on.
  services.resolved.enable = true;
  programs.windscribe.settings.dnsManager = "systemd-resolved";

  # The helper hard-resets PATH to /usr/sbin:/usr/bin:/sbin:/bin (src/helper/linux/main.cpp),
  # which is empty on NixOS, so WireGuard setup (ip, modprobe, ...) fails with error 9.
  # Give the helper, and only the helper, a private /usr/bin + /usr/sbin with its tools.
  systemd.services.windscribe-helper.serviceConfig.BindReadOnlyPaths =
    let
      tools = pkgs.buildEnv {
        name = "windscribe-helper-tools";
        paths = with pkgs; [
          bash coreutils ethtool gawk gnugrep gnused iproute2 iptables nftables
          iw kmod procps util-linux systemd networkmanager wireguard-tools
        ];
        pathsToLink = [ "/bin" "/sbin" ];
        ignoreCollisions = true; # e.g. `kill` is in both procps and util-linux
      };
    in [ "${tools}/bin:/usr/bin" "${tools}/bin:/usr/sbin" ];
}
