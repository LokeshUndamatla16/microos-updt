#!/usr/bin/env bash
# ==============================================================================
# MicroVerse - Small Live ISO Build & Optimization Engine
# ==============================================================================
set -eo pipefail

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

WORK_DIR="/root/microverse_work"
SRC_CHROOT="${WORK_DIR}/chroot"
SMALL_CHROOT="${WORK_DIR}/chroot_small"
BINARY_DIR="${WORK_DIR}/binary_small"
OUT_ISO="/media/sf_RustOSShare/microverse/out/microverse-small.iso"
SHA_FILE="/media/sf_RustOSShare/microverse/out/SHA256SUMS"

echo "[1/7] Creating optimized chroot clone from Stage 5 base..."
rm -rf "$SMALL_CHROOT" "$BINARY_DIR"
mkdir -p "$SMALL_CHROOT" "$BINARY_DIR/live"

# Fast rsync/cp of rootfs
echo "  -> Syncing rootfs files..."
rsync -a --exclude='/proc/*' --exclude='/sys/*' --exclude='/dev/*' --exclude='/run/*' "$SRC_CHROOT/" "$SMALL_CHROOT/"

echo "[2/7] Purging non-essential graphics, Mesa, and unneeded server firmware..."
# Safely mount kernel filesystems for chroot
mount -t proc none "$SMALL_CHROOT/proc" 2>/dev/null || true
mount -t sysfs none "$SMALL_CHROOT/sys" 2>/dev/null || true
mount --bind /dev "$SMALL_CHROOT/dev" 2>/dev/null || true
mount --bind /dev/pts "$SMALL_CHROOT/dev/pts" 2>/dev/null || true

chroot "$SMALL_CHROOT" /bin/bash -c "
  # Remove Mesa and server GPU packages (headless live OS)
  apt-get purge -y --allow-remove-essential \
    mesa-vulkan-drivers \
    libgl1-mesa-dri \
    libllvm15 \
    libz3-4 \
    firmware-amd-graphics \
    firmware-nvidia-tesla-535-gsp \
    nvidia-tesla-470-kernel-support \
    firmware-netronome \
    firmware-libertas \
    firmware-brcm80211 \
    firmware-sof-signed || true

  apt-get autoremove --purge -y || true
"

# Cleanly unmount filesystems
umount -lf "$SMALL_CHROOT/dev/pts" 2>/dev/null || true
umount -lf "$SMALL_CHROOT/dev" 2>/dev/null || true
umount -lf "$SMALL_CHROOT/sys" 2>/dev/null || true
umount -lf "$SMALL_CHROOT/proc" 2>/dev/null || true

echo "[3/7] Stripping documentation, man pages, non-English locales, and apt caches..."
strip "$SMALL_CHROOT/usr/local/bin/mv-info" 2>/dev/null || true
rm -rf "$SMALL_CHROOT/usr/share/doc/"*
rm -rf "$SMALL_CHROOT/usr/share/man/"*
rm -rf "$SMALL_CHROOT/usr/share/info/"*
rm -rf "$SMALL_CHROOT/usr/share/groff/"*
rm -rf "$SMALL_CHROOT/usr/share/lintian/"*
rm -rf "$SMALL_CHROOT/usr/share/linda/"*

# Retain only en locales
find "$SMALL_CHROOT/usr/share/locale" -mindepth 1 -maxdepth 1 ! -name 'en*' ! -name 'locale.alias' -exec rm -rf {} + 2>/dev/null || true

# Clean apt caches & lists (keep sources.list intact for apt update)
rm -rf "$SMALL_CHROOT/var/cache/apt/"*.bin
rm -rf "$SMALL_CHROOT/var/cache/apt/archives/"*.deb
rm -rf "$SMALL_CHROOT/var/lib/apt/lists/"*
mkdir -p "$SMALL_CHROOT/var/lib/apt/lists/partial"
mkdir -p "$SMALL_CHROOT/var/cache/apt/archives/partial"
rm -rf "$SMALL_CHROOT/tmp/"* "$SMALL_CHROOT/var/tmp/"* "$SMALL_CHROOT/var/log/"*

echo "[4/7] Installing boot performance logging service into small chroot..."
cat << 'EOF' > "$SMALL_CHROOT/etc/systemd/system/microverse-boot-bench.service"
[Unit]
Description=MicroVerse Boot Performance Logger
After=multi-user.target
Requires=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "echo '===RAW_SYSTEMD_ANALYZE_START===' > /dev/ttyS0; systemd-analyze > /dev/ttyS0 2>&1; echo '===RAW_SYSTEMD_BLAME_START===' > /dev/ttyS0; systemd-analyze blame | head -n 25 > /dev/ttyS0 2>&1; echo '===RAW_SYSTEMD_ANALYZE_END===' > /dev/ttyS0; systemd-analyze > /var/log/boot_analyze.txt 2>&1; systemd-analyze blame | head -n 25 >> /var/log/boot_analyze.txt 2>&1"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

mkdir -p "$SMALL_CHROOT/etc/systemd/system/multi-user.target.wants"
ln -sf /etc/systemd/system/microverse-boot-bench.service "$SMALL_CHROOT/etc/systemd/system/multi-user.target.wants/microverse-boot-bench.service"

echo "[5/7] Copying live bootloader files..."
cp -r "$WORK_DIR/binary/isolinux" "$BINARY_DIR/"
cp -r "$WORK_DIR/binary/syslinux" "$BINARY_DIR/" 2>/dev/null || true
cp -r "$WORK_DIR/binary/EFI" "$BINARY_DIR/"
cp -r "$WORK_DIR/binary/boot" "$BINARY_DIR/"
cp -r "$WORK_DIR/binary/.disk" "$BINARY_DIR/"
cp -f "$WORK_DIR/binary/efi.img" "$BINARY_DIR/" 2>/dev/null || true

# Copy kernel & initrd into live/
mkdir -p "$BINARY_DIR/live"
cp "$SMALL_CHROOT/boot/vmlinuz-"* "$BINARY_DIR/live/vmlinuz"
cp "$SMALL_CHROOT/boot/initrd.img-"* "$BINARY_DIR/live/initrd.img"

echo "[6/7] Building maximum compression Squashfs (-comp xz -Xbcj x86 -b 1M, processors 2, nice 10)..."
nice -n 10 mksquashfs "$SMALL_CHROOT" "$BINARY_DIR/live/filesystem.squashfs" \
  -comp xz -Xbcj x86 -b 1M -processors 2 -noappend

# Generate md5sum
(
  cd "$BINARY_DIR"
  find . -type f ! -path './isolinux/*' ! -path './syslinux/*' ! -path './EFI/*' -exec md5sum {} + > md5sum.txt
)

echo "[7/7] Mastering Hybrid ISO with xorriso (BIOS MBR + UEFI EFI partition)..."
xorriso -as mkisofs \
  -r -V "MICROVERSE_SMALL" \
  -o "$OUT_ISO" \
  -J -joliet-long -cache-inodes \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -b isolinux/isolinux.bin \
  -c isolinux/boot.cat \
  -boot-load-size 4 -boot-info-table -no-emul-boot \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  "$BINARY_DIR"

sync

echo "[SUCCESS] Generated: $OUT_ISO"
ls -lh "$OUT_ISO"

# Compute and record sha256sum
(
  cd /media/sf_RustOSShare/microverse/out
  sha256sum microverse-small.iso >> "$SHA_FILE"
)
echo "[INFO] Appended checksum to SHA256SUMS."
