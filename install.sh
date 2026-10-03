#!/usr/bin/env bash
# Installs hjc-legion-nix (NixOS for the Legion Go S) from the NixOS live USB.
# Usage:  sudo bash install.sh [/dev/nvme0n1]
# WARNING: wipes the chosen disk entirely.
set -euo pipefail

REPO="https://github.com/hjcoggan/hjc-legion-nix"
HOST="legion-go-s"
USER_NAME="heath"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo bash $0 [disk]"; exit 1
fi
if [[ ! -d /sys/firmware/efi ]]; then
  echo "Not booted in UEFI mode. Reboot the USB in UEFI mode."; exit 1
fi

export NIX_CONFIG="experimental-features = nix-command flakes"

# --- Network ---------------------------------------------------------------
if ! curl -fsS --max-time 8 -o /dev/null https://github.com; then
  echo "No internet. Connect first (e.g. run 'nmtui'), then re-run this script."; exit 1
fi

# --- Pick disk -------------------------------------------------------------
DISK="${1:-}"
if [[ -z "$DISK" ]]; then
  echo "Available disks:"
  lsblk -d -o NAME,SIZE,MODEL,TRAN -e 7,11
  read -rp "Install to which disk? (e.g. /dev/nvme0n1): " DISK
fi
[[ -b "$DISK" ]] || { echo "$DISK is not a block device."; exit 1; }

echo
lsblk "$DISK"
echo
echo "ALL DATA ON $DISK WILL BE ERASED."
read -rp "Type ERASE to continue: " CONFIRM
[[ "$CONFIRM" == "ERASE" ]] || { echo "Aborted."; exit 1; }

# nvme0n1 -> nvme0n1p1 ; sda -> sda1
if [[ "$DISK" =~ [0-9]$ ]]; then P="${DISK}p"; else P="$DISK"; fi
BOOT="${P}1"
ROOT="${P}2"

# --- Password up front (so the install can run unattended) -----------------
while true; do
  read -rsp "Set password for $USER_NAME: " PW1; echo
  read -rsp "Confirm password: " PW2; echo
  [[ -n "$PW1" && "$PW1" == "$PW2" ]] && break
  echo "Passwords empty or don't match, try again."
done

# --- Partition & format ----------------------------------------------------
umount -R /mnt 2>/dev/null || true
swapoff -a 2>/dev/null || true
wipefs -af "$DISK"
parted -s "$DISK" -- mklabel gpt
parted -s "$DISK" -- mkpart ESP fat32 1MiB 1GiB
parted -s "$DISK" -- set 1 esp on
parted -s "$DISK" -- mkpart root btrfs 1GiB 100%
udevadm settle
sleep 1

mkfs.fat -F32 -n boot "$BOOT"
mkfs.btrfs -f -L nixos "$ROOT"

mount "$ROOT" /mnt
for sv in @ @home @nix @log; do btrfs subvolume create "/mnt/$sv"; done
umount /mnt

OPTS="compress=zstd:1,noatime"
mount -o "$OPTS,subvol=@" "$ROOT" /mnt
mkdir -p /mnt/home /mnt/nix /mnt/var/log /mnt/boot
mount -o "$OPTS,subvol=@home" "$ROOT" /mnt/home
mount -o "$OPTS,subvol=@nix"  "$ROOT" /mnt/nix
mount -o "$OPTS,subvol=@log"  "$ROOT" /mnt/var/log
mount -o umask=0077 "$BOOT" /mnt/boot

# --- Config ----------------------------------------------------------------
mkdir -p /mnt/etc
if command -v git >/dev/null; then
  git clone "$REPO" /mnt/etc/nixos
else
  nix-shell -p git --run "git clone $REPO /mnt/etc/nixos"
fi

nixos-generate-config --root /mnt --show-hardware-config \
  > "/mnt/etc/nixos/hosts/$HOST/hardware-configuration.nix"

# Flakes ignore untracked files, so stage the generated hardware config.
GIT="git"; command -v git >/dev/null || GIT="nix-shell -p git --run"
if [[ "$GIT" == "git" ]]; then
  git -C /mnt/etc/nixos add -A
else
  nix-shell -p git --run "git -C /mnt/etc/nixos add -A"
fi

# --- Install ---------------------------------------------------------------
nixos-install --flake "/mnt/etc/nixos#$HOST" --no-root-passwd

# --- User password & ownership --------------------------------------------
echo "$USER_NAME:$PW1" | nixos-enter --root /mnt -c chpasswd
# /etc/nixos is meant to be owned by the user (uid 1000, group users)
chown -R 1000:100 /mnt/etc/nixos

echo
echo "Done. Remove the USB and run: reboot"
