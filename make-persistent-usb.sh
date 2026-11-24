#!/usr/bin/env bash
# ==============================================================================
# MicroVerse - Add Persistence Partition to Live USB
# ==============================================================================
# This script provisions an ext4 persistence partition on the unallocated space
# of a flashed MicroVerse Live USB flash drive.
#
# Persistence specification:
# - Partition filesystem: ext4
# - Volume Label: "persistence"
# - Configuration file: /persistence.conf containing "/ union"
#
# When booting with the "Live with persistence" menu option (boot param 'persistence'),
# live-boot automatically searches for any partition labeled 'persistence', mounts
# it, and sets up a read-write overlay union mount on root ('/').
# ==============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo -e "\e[1;31m[ERROR] This script must be run as root (sudo ./make-persistent-usb.sh <device>)\e[0m" >&2
    exit 1
fi

TARGET_DEV="${1:-}"

if [[ -z "$TARGET_DEV" ]]; then
    echo "Usage: sudo $0 <usb-device>"
    echo "Example: sudo $0 /dev/sdb"
    echo ""
    echo "Available block devices:"
    lsblk -d -o NAME,SIZE,TYPE,TRAN,RM,MODEL
    exit 1
fi

if [[ "$TARGET_DEV" != /dev/* ]]; then
    TARGET_DEV="/dev/$TARGET_DEV"
fi

if [[ ! -b "$TARGET_DEV" ]]; then
    echo -e "\e[1;31m[ERROR] Block device '$TARGET_DEV' does not exist!\e[0m" >&2
    exit 1
fi

DEV_BASE=$(basename "$TARGET_DEV")

# --- Safety check: Never operate on system disk ---
ROOT_SOURCE=$(findmnt -n -o SOURCE / || true)
BOOT_SOURCE=$(findmnt -n -o SOURCE /boot || true)

for SYS_DEV in "$ROOT_SOURCE" "$BOOT_SOURCE"; do
    if [[ -n "$SYS_DEV" ]]; then
        SYS_PARENT="/dev/$(lsblk -no PKNAME "$SYS_DEV" 2>/dev/null || true)"
        if [[ "$TARGET_DEV" == "$SYS_DEV" || "$TARGET_DEV" == "$SYS_PARENT" ]]; then
            echo -e "\e[1;31m[FATAL SAFETY ABORT] '$TARGET_DEV' is a system disk!\e[0m" >&2
            exit 1
        fi
    fi
done

echo -e "\e[1;36m======================================================================\e[0m"
echo -e "\e[1;37m        MicroVerse - Live USB Persistence Provisioner                \e[0m"
echo -e "\e[1;36m======================================================================\e[0m"
echo "Target USB Drive: $TARGET_DEV"
lsblk "$TARGET_DEV"
echo ""

read -rp "Proceed to create a persistence partition in free space on $TARGET_DEV? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Find the next free partition number using parted / fdisk
echo -e "\e[1;32m[INFO] Analyzing partition table on $TARGET_DEV...\e[0m"

# Get current number of partitions
NUM_PARTS=$(lsblk -n -r -o TYPE "$TARGET_DEV" | grep -c "part" || true)
NEXT_PART_NUM=$((NUM_PARTS + 1))

# For MBR partition tables, if 4 primary partitions exist, we cannot add another primary.
# However, iso-hybrid creates partition 1 (ISO9660) and partition 2 (EFI).
# So partition 3 is normally free!
echo -e "\e[1;32m[INFO] Creating partition $NEXT_PART_NUM in remaining free space...\e[0m"

# Use parted to add partition to fill the rest of the disk
parted --script "$TARGET_DEV" mkpart primary ext4 0% 100% 2>/dev/null || \
parted --script "$TARGET_DEV" mkpart primary ext4 1024MiB 100% 2>/dev/null || \
(
    # Fallback to fdisk if parted gives align warning
    echo -e "n\np\n$NEXT_PART_NUM\n\n\nw" | fdisk "$TARGET_DEV"
)

# Notify kernel of partition changes
partprobe "$TARGET_DEV" 2>/dev/null || true
udevadm settle || sleep 2

# Identify newly created partition name
NEW_PART="${TARGET_DEV}${NEXT_PART_NUM}"
if [[ ! -b "$NEW_PART" ]]; then
    NEW_PART="${TARGET_DEV}p${NEXT_PART_NUM}"
fi

if [[ ! -b "$NEW_PART" ]]; then
    # Search for latest partition block device
    NEW_PART=$(lsblk -r -n -o NAME,TYPE "$TARGET_DEV" | grep "part" | tail -n1 | awk '{print "/dev/" $1}')
fi

echo -e "\e[1;32m[INFO] Formatting persistence partition $NEW_PART with ext4 (label: persistence)...\e[0m"
mkfs.ext4 -L "persistence" -F "$NEW_PART"

echo -e "\e[1;32m[INFO] Writing persistence.conf with '/ union'...\e[0m"
TMP_MOUNT=$(mktemp -d /tmp/persistence_mnt.XXXXXX)
mount "$NEW_PART" "$TMP_MOUNT"
echo "/ union" > "$TMP_MOUNT/persistence.conf"
sync
umount "$TMP_MOUNT"
rmdir "$TMP_MOUNT"

echo ""
echo -e "\e[1;32m======================================================================\e[0m"
echo -e "\e[1;32m  SUCCESS: Persistence partition configured on $NEW_PART!             \e[0m"
echo -e "\e[1;32m======================================================================\e[0m"
echo "When booting your USB, select:"
echo "  'Live with persistence'"
echo "Changes, Wi-Fi networks, and apt packages will now persist across reboots."
