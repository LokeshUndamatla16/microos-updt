#!/usr/bin/env bash
# ==============================================================================
# MicroVerse - Hardware Compatibility & Missing Firmware Checker
# ==============================================================================
# Inspects detected hardware (CPU, GPU, Wi-Fi, Audio) and checks kernel logs
# for any requested firmware files that could not be loaded.
# ==============================================================================

set -euo pipefail

echo -e "\e[1;36m======================================================================\e[0m"
echo -e "\e[1;37m        MicroVerse Hardware Compatibility Audit (hwcheck)             \e[0m"
echo -e "\e[1;36m======================================================================\e[0m"

# 1. CPU AUDIT
echo -e "\n\e[1;33m[1] CPU ARCHITECTURE & PROCESSOR INFO:\e[0m"
if command -v lscpu >/dev/null 2>&1; then
    lscpu | grep -E "Model name|Architecture|CPU\(s\):|Thread\(s\) per core|Vendor ID|Virtualization:" || true
else
    grep -E "model name|cpu cores|vendor_id" /proc/cpuinfo | head -n 3 || true
fi

# 2. GPU & DISPLAY
echo -e "\n\e[1;33m[2] GPU & GRAPHICS HARDWARE:\e[0m"
if command -v lspci >/dev/null 2>&1; then
    lspci -nnk | grep -iA 3 -E "vga|3d|display" || echo "  No PCI display controller detected."
else
    echo "  [INFO] lspci not installed."
fi
if [[ -d /sys/class/drm ]]; then
    echo "  DRM Connectors:"
    for card in /sys/class/drm/card*-*; do
        if [[ -f "$card/status" ]]; then
            echo "    $(basename "$card"): $(cat "$card/status")"
        fi
    done
fi

# 3. WI-FI & NETWORKING
echo -e "\n\e[1;33m[3] NETWORK CONTROLLERS & WI-FI CHIPSETS:\e[0m"
if command -v lspci >/dev/null 2>&1; then
    lspci -nnk | grep -iA 3 -E "network|ethernet|wireless" || true
fi
if command -v ip >/dev/null 2>&1; then
    echo "  Active Network Interfaces:"
    ip -br link show || true
fi
if command -v iw >/dev/null 2>&1; then
    echo "  Wireless Interfaces (iw):"
    iw dev 2>/dev/null || true
fi
if command -v rfkill >/dev/null 2>&1; then
    echo "  RF-Kill Status:"
    rfkill list || true
fi

# 4. AUDIO SUBSYSTEM
echo -e "\n\e[1;33m[4] AUDIO CONTROLLER & CODECS:\e[0m"
if command -v lspci >/dev/null 2>&1; then
    lspci -nnk | grep -iA 3 -E "audio" || true
fi
if [[ -f /proc/asound/cards ]]; then
    echo "  ALSA Sound Cards:"
    cat /proc/asound/cards
else
    echo "  No ALSA sound cards detected in /proc/asound/cards."
fi

# 5. MISSING FIRMWARE AUDIT
echo -e "\n\e[1;33m[5] MISSING FIRMWARE AUDIT:\e[0m"
MISSING_FW=""
if command -v dmesg >/dev/null 2>&1; then
    MISSING_FW=$(dmesg 2>/dev/null | grep -i -E "firmware.*failed|firmware.*missing|failed to load.*firmware" || true)
fi

if [[ -n "$MISSING_FW" ]]; then
    echo -e "\e[1;31m[WARNING] The kernel logged missing firmware requests:\e[0m"
    echo "$MISSING_FW"
    echo ""
    echo "RECOMMENDATION:"
    echo "  Install additional non-free firmware packages from Debian repository:"
    echo "    sudo apt update && sudo apt install firmware-linux firmware-linux-nonfree"
else
    echo -e "\e[1;32m[OK] No missing firmware errors detected in kernel ring buffer.\e[0m"
    echo "All active hardware drivers successfully loaded their firmware."
fi

echo -e "\n\e[1;36m======================================================================\e[0m"
echo -e "\e[1;37m                   End of Hardware Report                             \e[0m"
echo -e "\e[1;36m======================================================================\e[0m"
