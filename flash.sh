#!/usr/bin/env bash
# ==============================================================================
# MicroVerse - Safe USB Flash Script
# ==============================================================================
# This script safely writes a MicroVerse hybrid ISO to a USB flash drive using dd.
#
# ALTERNATIVE FLASHING TOOLS:
# 1. Windows: Rufus (https://rufus.ie/)
#    - Select the USB drive and MicroVerse ISO.
#    - IMPORTANT: When prompted, select "Write in DD Image mode" (NOT ISO mode)
#      to ensure the hybrid MBR and EFI boot partition are written verbatim.
# 2. Cross-Platform: balenaEtcher (https://etcher.balena.io/)
#    - Select ISO -> Select USB Drive -> Flash! Etcher automatically writes raw images.
# 3. Multi-boot: Ventoy (https://www.ventoy.net/)
#    - Install Ventoy on USB, then drag-and-drop microverse-final.iso into the drive.
# ==============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo -e "\e[1;31m[ERROR] This script must be run as root (e.g. sudo ./flash.sh <iso> <dev>)\e[0m" >&2
    exit 1
fi

ISO_PATH="${1:-}"
TARGET_DEV="${2:-}"

function usage() {
    echo "Usage: sudo $0 <path-to-iso> [target-device]"
    echo ""
    echo "Example: sudo $0 ./out/microverse-final.iso /dev/sdb"
    echo ""
    echo "Available disks on this system:"
    lsblk -d -o NAME,SIZE,MODEL,TRAN,RM,RO,TYPE || true
    echo ""
    echo "ALTERNATIVE FLASHING TOOLS:"
    echo "  - Windows: Rufus (MUST choose 'Write in DD Image mode')"
    echo "  - macOS/Linux/Windows: balenaEtcher"
    echo "  - Any OS: Ventoy (copy .iso to Ventoy USB partition)"
    exit 1
}

if [[ -z "$ISO_PATH" || ! -f "$ISO_PATH" ]]; then
    echo -e "\e[1;31m[ERROR] ISO file not found or not specified: '$ISO_PATH'\e[0m"
    usage
fi

echo -e "\e[1;36m======================================================================\e[0m"
echo -e "\e[1;37m                 MicroVerse Safe USB Flasher                          \e[0m"
echo -e "\e[1;36m======================================================================\e[0m"
echo -e "  ISO Source: \e[1;32m$ISO_PATH\e[0m ($(du -h "$ISO_PATH" | cut -f1))"

if [[ -z "$TARGET_DEV" ]]; then
    echo ""
    echo -e "\e[1;33mAvailable block devices:\e[0m"
    lsblk -d -o NAME,SIZE,TYPE,TRAN,RM,MODEL
    echo ""
    read -rp "Enter target USB block device (e.g. sdb or /dev/sdb): " TARGET_DEV
fi

# Normalize device name
if [[ "$TARGET_DEV" != /dev/* ]]; then
    TARGET_DEV="/dev/$TARGET_DEV"
fi

if [[ ! -b "$TARGET_DEV" ]]; then
    echo -e "\e[1;31m[ERROR] Block device '$TARGET_DEV' does not exist!\e[0m" >&2
    exit 1
fi

DEV_BASE=$(basename "$TARGET_DEV")

# --- SAFETY CHECK 1: Ensure it's a whole disk, not a partition ---
DEV_TYPE=$(lsblk -no TYPE "$TARGET_DEV" | head -n1 || true)
if [[ "$DEV_TYPE" == "part" ]]; then
    echo -e "\e[1;31m[ERROR] '$TARGET_DEV' is a partition, not a whole disk!\e[0m" >&2
    echo "Specify the parent disk device (e.g. /dev/sdb instead of /dev/sdb1)." >&2
    exit 1
fi

# --- SAFETY CHECK 2: Refuse to write to system / root / boot disk ---
ROOT_SOURCE=$(findmnt -n -o SOURCE / || true)
BOOT_SOURCE=$(findmnt -n -o SOURCE /boot || true)

for SYS_DEV in "$ROOT_SOURCE" "$BOOT_SOURCE"; do
    if [[ -n "$SYS_DEV" ]]; then
        SYS_PARENT="/dev/$(lsblk -no PKNAME "$SYS_DEV" 2>/dev/null || true)"
        if [[ "$TARGET_DEV" == "$SYS_DEV" || "$TARGET_DEV" == "$SYS_PARENT" ]]; then
            echo -e "\e[1;31m[FATAL SAFETY ABORT] '$TARGET_DEV' contains the running system or /boot filesystem!\e[0m" >&2
            echo "Target matches: $SYS_DEV" >&2
            exit 1
        fi
    fi
done

# --- SAFETY CHECK 3: Check for mounted partitions on target ---
MOUNTED_PARTS=$(lsblk -no MOUNTPOINT "$TARGET_DEV" | grep -v '^$' || true)
if [[ -n "$MOUNTED_PARTS" ]]; then
    echo -e "\e[1;33m[WARNING] Partitions on '$TARGET_DEV' are currently mounted:\e[0m"
    lsblk "$TARGET_DEV"
    read -rp "Unmount all partitions on '$TARGET_DEV' now? [y/N]: " UNMOUNT_CONFIRM
    if [[ "$UNMOUNT_CONFIRM" =~ ^[Yy]$ ]]; then
        umount "${TARGET_DEV}"* 2>/dev/null || true
    else
        echo "Aborting at user request."
        exit 1
    fi
fi

# --- SAFETY CHECK 4: Show details and require explicit confirmation ---
echo ""
echo -e "\e[1;31m----------------------------------------------------------------------\e[0m"
echo -e "\e[1;31m                       CRITICAL WARNING                               \e[0m"
echo -e "\e[1;31m----------------------------------------------------------------------\e[0m"
echo "Target Device: $TARGET_DEV"
lsblk -o NAME,SIZE,TYPE,TRAN,RM,MODEL "$TARGET_DEV"
echo ""
echo "ALL DATA ON $TARGET_DEV WILL BE PERMANENTLY ERASED AND OVERWRITTEN!"
echo ""
read -rp "To confirm, type the exact device name '$DEV_BASE': " CONFIRM_NAME

if [[ "$CONFIRM_NAME" != "$DEV_BASE" ]]; then
    echo -e "\e[1;33mConfirmation mismatch ('$CONFIRM_NAME' != '$DEV_BASE'). Operation aborted safely.\e[0m"
    exit 1
fi

echo ""
echo -e "\e[1;32m[INFO] Writing '$ISO_PATH' to '$TARGET_DEV'... Please wait.\e[0m"
dd if="$ISO_PATH" of="$TARGET_DEV" bs=4M status=progress oflag=sync conv=fsync

echo -e "\e[1;32m[INFO] Syncing filesystem buffers...\e[0m"
sync

echo ""
echo -e "\e[1;32m======================================================================\e[0m"
echo -e "\e[1;32m  SUCCESS: MicroVerse Live OS flashed to $TARGET_DEV successfully!   \e[0m"
echo -e "\e[1;32m======================================================================\e[0m"
echo "You can now safely remove the USB and boot it on any x86_64 computer in UEFI or BIOS mode."
