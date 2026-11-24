#!/usr/bin/env bash
set -eo pipefail

CHROOT="/root/microverse_work/chroot"
BINARY="/root/microverse_work/binary"
OUT_ISO="/media/sf_RustOSShare/microverse/out/microverse-wifi.iso"
SHA_FILE="/media/sf_RustOSShare/microverse/out/SHA256SUMS"

echo "[1/4] Installing 'wifi' and 'wifi-connect' helper into chroot..."
cat << 'EOF' > "$CHROOT/usr/local/bin/wifi"
#!/usr/bin/env bash
echo "=============================================="
echo "    MicroVerse Wi-Fi Connection Manager       "
echo "=============================================="
rfkill unblock wifi 2>/dev/null || true

if [[ -n "$1" ]]; then
    SSID="$1"
    PASS="$2"
    if [[ -z "$PASS" ]]; then
        read -s -p "Enter password for '$SSID': " PASS
        echo ""
    fi
    echo "Connecting to '$SSID'..."
    nmcli dev wifi connect "$SSID" password "$PASS"
    exit $?
fi

echo "Scanning for available Wi-Fi networks..."
nmcli dev wifi rescan 2>/dev/null || true
sleep 1
nmcli -c yes dev wifi list

echo ""
echo "Options:"
echo "  - Connect via command:  wifi \"SSID\" \"PASSWORD\""
echo "  - Interactive menu:     nmtui"
echo ""
read -t 15 -p "Launch interactive Wi-Fi menu (nmtui) now? [Y/n]: " ans || ans="Y"
if [[ "$ans" =~ ^[Nn] ]]; then
    echo "Exiting. To launch manually anytime, type: nmtui"
else
    nmtui
fi
EOF
chmod +x "$CHROOT/usr/local/bin/wifi"
ln -sf /usr/local/bin/wifi "$CHROOT/usr/local/bin/wifi-connect"

echo "[2/4] Updating /etc/issue and /etc/motd with Wi-Fi instructions..."
cat << 'EOF' > "$CHROOT/etc/issue"

MicroVerse 1.0 (Debian GNU/Linux 12 bookworm) \n \l

Default user: microverse | Password: live (sudo enabled)
* Ethernet: Auto-connects on plug-in (DHCP active).
* Wi-Fi:    Type 'wifi' or 'nmtui' to select and connect.
* Hardware: Type 'sudo hwcheck.sh' for diagnostics.

EOF

cat << 'EOF' > "$CHROOT/etc/motd"

=======================================================
 Welcome to MicroVerse Live OS (Debian 12 Bookworm)
=======================================================
 * Ethernet is automatically configured via DHCP.
 * To connect to Wi-Fi, run:
     wifi                         (scans and opens interactive menu)
     wifi "MyNetwork" "Password"  (instant connection)
     nmtui                        (NetworkManager text GUI)
 * Diagnostic tools:
     mv-info                      (system & architecture telemetry)
     sudo hwcheck.sh              (hardware & driver audit)
=======================================================

EOF

echo "[3/4] Ensuring rfkill unblock wifi service at boot..."
cat << 'EOF' > "$CHROOT/etc/systemd/system/unblock-wifi.service"
[Unit]
Description=Unblock Wi-Fi and Radio Devices
Before=NetworkManager.service

[Service]
Type=oneshot
ExecStart=/usr/sbin/rfkill unblock wifi
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
mkdir -p "$CHROOT/etc/systemd/system/multi-user.target.wants"
ln -sf /etc/systemd/system/unblock-wifi.service "$CHROOT/etc/systemd/system/multi-user.target.wants/unblock-wifi.service"

echo "[4/4] Building fast zstd Squashfs & mastering out/microverse-wifi.iso..."
mksquashfs "$CHROOT" "$BINARY/live/filesystem.squashfs" -comp zstd -processors $(nproc) -noappend

# Master hybrid ISO with xorriso
xorriso -as mkisofs \
  -r -V "MICROVERSE_WIFI" \
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
  "$BINARY"

sync

echo "[SUCCESS] Generated: $OUT_ISO"
ls -lh "$OUT_ISO"

# Append sha256 checksum
cd /media/sf_RustOSShare/microverse/out
sha256sum microverse-wifi.iso >> "$SHA_FILE"
echo "SHA256 recorded in SHA256SUMS."
