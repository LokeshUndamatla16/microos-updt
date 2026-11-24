#!/usr/bin/env bash
echo "=== NETWORK PACKAGES IN CHROOT ==="
chroot /root/microverse_work/chroot dpkg -l | grep -E 'network-manager|wpasupplicant|wireless|firmware|iproute|rfkill|iw|curl|wget'

echo "=== NETWORKMANAGER CONFIGURATION ==="
cat /root/microverse_work/chroot/etc/NetworkManager/NetworkManager.conf 2>/dev/null || echo "No NM conf"

echo "=== NETWORK INTERFACES CONFIGURATION ==="
cat /root/microverse_work/chroot/etc/network/interfaces 2>/dev/null || echo "No /etc/network/interfaces"

echo "=== NETWORK SERVICES ENABLEMENT ==="
chroot /root/microverse_work/chroot systemctl is-enabled NetworkManager 2>/dev/null || true
chroot /root/microverse_work/chroot systemctl is-enabled wpa_supplicant 2>/dev/null || true
