# hjc-legion-nix

Touch-friendly, SteamOS-like NixOS for the **Lenovo Legion Go S** (Ryzen Z2 Go). Based on
[hjcoggan-nix](https://github.com/hjcoggan/hjcoggan-nix) (the gaming PC config).

- **Steam Big Picture in SteamOS mode** (Steam Deck UI on gamescope, via
  [Jovian-NixOS](https://jovian-experiments.github.io/Jovian-NixOS/)). Always the default.
- **KDE Plasma Bigscreen** as the second environment. "Switch to Desktop" in Steam opens it.
- **Touch login screen** (SDDM, on-screen keyboard) at every boot to pick between the two.
- **Update System**: a one-tap updater with a big progress dialog. In Plasma Bigscreen it is an
  app; in Steam it is a shortcut in the library (added automatically once you have signed in).
- Hardware: newest kernel (Go S controller drivers), InputPlumber for controllers / back buttons /
  gyro, Bluetooth, Wi-Fi 7 and audio firmware, power profiles, LVFS firmware updates, automount
  for SD cards and USB drives.
- Apps: Firefox, Heroic, Lutris, Faugus Launcher, ProtonUp-Qt, MangoHud, Proton-GE.

## Layout
```
flake.nix                  inputs: nixpkgs-unstable, jovian
hosts/legion-go-s/         host settings (+ hardware-configuration.nix generated at install)
modules/base.nix           nix, boot, networking, audio, git
modules/hardware.nix       Legion Go S hardware support
modules/desktop.nix        touch login screen + Steam / Plasma Bigscreen sessions
modules/gaming.nix         Steam Deck UI (Jovian), Proton-GE, automount
modules/apps.nix           apps
modules/update.nix         "Update System" app, updater service, Steam shortcuts
```

## Updating
Tap **Update System** (Steam library or the Bigscreen app list). Or from a terminal:
```bash
sudo systemctl start hjc-update.service   # fetch settings + packages, install for next boot
```
The config lives in `/etc/nixos` (owned by the user). To change it by hand, edit there, then:
```bash
sudo nixos-rebuild switch --flake /etc/nixos#legion-go-s
```
