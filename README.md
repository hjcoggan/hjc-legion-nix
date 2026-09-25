# hjcoggan-nix

NixOS flake for my gaming PC — Ryzen 7 7700 + Radeon RX 9070 XT.

- **Niri** (primary) with **Noctalia** shell, config based on CachyOS's niri settings
- **KDE Plasma 6** as a backup session
- **Steam Big Picture (gamescope)** session for a SteamOS-like couch experience
- SDDM login screen (Astronaut theme) to switch between them
- Steam + Proton-GE, gamemode, gamescope, MangoHud, LACT, ananicy-cpp (CachyOS rules)
- Apps: Firefox, Opencode, Faugus Launcher, ProtonUp-Qt, Heroic
- USB/external drives automount (udisks2 + udiskie in niri; Plasma native)

## Layout
```
flake.nix                 inputs: nixpkgs-unstable, home-manager, noctalia
hosts/gaming-pc/          host settings (+ hardware-configuration.nix you generate)
modules/                  base, amd, desktop, gaming, apps
home/                     home-manager: niri config, udiskie
```

## Install
From the NixOS installer (after partitioning & mounting at /mnt):
```bash
git clone https://github.com/hjcoggan/hjcoggan-nix /mnt/etc/nixos
nixos-generate-config --root /mnt --show-hardware-config > /mnt/etc/nixos/hosts/gaming-pc/hardware-configuration.nix
cd /mnt/etc/nixos && git add -A
nixos-install --flake .#gaming-pc
```

## Rebuild
```bash
sudo nixos-rebuild switch --flake ~/hjcoggan-nix#gaming-pc
```
