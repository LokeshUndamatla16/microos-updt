#!/usr/bin/env bash
set -eo pipefail

CHROOT_DIR="/root/microverse_work/chroot"
LOG_FILE="/media/sf_RustOSShare/microverse/out/snap_check.log"

echo "=== SNAP AND SNAP-STORE AUDIT ===" > "$LOG_FILE"
date -u >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo "[1] Checking dpkg packages related to snap in chroot:" >> "$LOG_FILE"
chroot "$CHROOT_DIR" dpkg -l | grep -iE "snap" >> "$LOG_FILE" 2>&1 || echo "No snap packages found via dpkg" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo "[2] Checking for snap binary:" >> "$LOG_FILE"
chroot "$CHROOT_DIR" which snap >> "$LOG_FILE" 2>&1 || echo "snap binary not found" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo "[3] Checking for snap-store binary or files in chroot:" >> "$LOG_FILE"
chroot "$CHROOT_DIR" which snap-store >> "$LOG_FILE" 2>&1 || echo "snap-store executable not in PATH" >> "$LOG_FILE"
find "$CHROOT_DIR/snap" "$CHROOT_DIR/var/lib/snapd" -name "*snap-store*" 2>/dev/null >> "$LOG_FILE" || echo "No snap-store files found in /snap or /var/lib/snapd" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo "[4] Attempting 'snap install snap-store' in chroot (with 15s timeout):" >> "$LOG_FILE"
timeout 15 chroot "$CHROOT_DIR" snap install snap-store >> "$LOG_FILE" 2>&1 || echo "Command exited with status $?" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo "[5] Checking snapd service enablement:" >> "$LOG_FILE"
chroot "$CHROOT_DIR" systemctl is-enabled snapd.socket snapd.service 2>/dev/null >> "$LOG_FILE" || true
echo "" >> "$LOG_FILE"

echo "=== SNAP AUDIT COMPLETE ===" >> "$LOG_FILE"
sync
