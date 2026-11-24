#!/usr/bin/env bash
set -eo pipefail

echo "=== DIAGNOSING CANONICAL SNAP APIS & IP PROTOCOLS ==="

echo "--- 1. Testing curl -4 against Snapcraft API ---"
curl -4 -v -m 15 -H "Snap-Device-Series: 16" https://api.snapcraft.io/v2/snaps/info/snap-store -o /tmp/snap_store_v4.json 2> /tmp/curl_v4.err || echo "curl -4 exited with $?"
echo "curl -4 output:"
head -n 20 /tmp/curl_v4.err
if [[ -f /tmp/snap_store_v4.json ]]; then
    echo "v4 JSON bytes: $(stat -c %s /tmp/snap_store_v4.json)"
fi

echo "--- 2. Testing curl -6 against Snapcraft API ---"
curl -6 -v -m 15 -H "Snap-Device-Series: 16" https://api.snapcraft.io/v2/snaps/info/snap-store -o /tmp/snap_store_v6.json 2> /tmp/curl_v6.err || echo "curl -6 exited with $?"
echo "curl -6 output:"
head -n 20 /tmp/curl_v6.err
if [[ -f /tmp/snap_store_v6.json ]]; then
    echo "v6 JSON bytes: $(stat -c %s /tmp/snap_store_v6.json)"
fi

echo "--- 3. Testing Package Availability for Fallback (gnome-software) ---"
apt-cache policy gnome-software gnome-software-plugin-snap xfce4 lightdm network-manager-gnome

echo "=== DIAGNOSIS COMPLETE ==="
