#!/usr/bin/env bash
# MicroVerse Wi-Fi Connection Manager
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
