#!/usr/bin/env bash
# ==============================================================================
# MicroVerse - Automated Boot Performance Measurement Harness
# ==============================================================================
set -eo pipefail

ISO_SRC="$1"
STAGE="$2"
MODE="${3:-UEFI}"
TIMEOUT="${4:-450}"

if [[ -z "$ISO_SRC" || -z "$STAGE" ]]; then
    echo "Usage: $0 <iso_path> <stage_name> [BIOS|UEFI] [timeout_seconds]"
    exit 1
fi

LOCAL_ISO="/tmp/test_${STAGE}_${MODE}.iso"
BOOT_LOG="/tmp/boot_${STAGE}_${MODE}.log"
MON_SOCK="/tmp/mon_${STAGE}_${MODE}.sock"
RAW_OUT="/media/sf_RustOSShare/microverse/out/systemd_raw_${STAGE}.txt"

echo "=== [START] Boot Benchmark for $STAGE ($MODE mode) ==="
echo "  Source ISO: $ISO_SRC"
echo "  Copying ISO to local fast storage ($LOCAL_ISO)..."
cp "$ISO_SRC" "$LOCAL_ISO"
rm -f "$BOOT_LOG" "$MON_SOCK" "$RAW_OUT"

OVMF_BIOS="/usr/share/ovmf/OVMF.fd"
if [[ ! -f "$OVMF_BIOS" ]]; then
    OVMF_BIOS="/usr/share/OVMF/OVMF_CODE_4M.fd"
fi

QEMU_ARGS=(
    nice -n 10
    qemu-system-x86_64
    -m 1024
    -smp 1
    -vga std
    -display none
    -device virtio-rng-pci
    -device qemu-xhci
    -device usb-storage,drive=usb,bootindex=1
    -drive if=none,id=usb,format=raw,readonly=on,file="$LOCAL_ISO"
    -netdev user,id=net0
    -device virtio-net-pci,netdev=net0
    -serial file:"$BOOT_LOG"
    -monitor unix:"$MON_SOCK",server,nowait
    -no-reboot
)

if [[ "$MODE" == "UEFI" ]]; then
    QEMU_ARGS+=(-bios "$OVMF_BIOS")
fi

echo "  Launching QEMU (nice -n 10, smp 2)..."
"${QEMU_ARGS[@]}" >/dev/null 2>&1 &
QPID=$!

# Send Enter after 2 seconds to skip bootloader delay
(
    sleep 2
    if [[ -S "$MON_SOCK" ]]; then
        python3 -c "import socket; s = socket.socket(socket.AF_UNIX); s.settimeout(2); s.connect('$MON_SOCK'); s.sendall(b'sendkey ret\n'); s.close()" 2>/dev/null || true
    fi
) </dev/null >/dev/null 2>&1 &

echo "  Polling for boot completion (timeout: ${TIMEOUT}s)..."
waited=0
booted=false

while [[ $waited -lt $TIMEOUT ]]; do
    if ! kill -0 "$QPID" 2>/dev/null; then
        echo "  [WARN] QEMU process exited early at ${waited}s."
        break
    fi

    if [[ -f "$BOOT_LOG" ]]; then
        if grep -q -E "login:|microverse@|Linux debian|Startup finished|mv-info" "$BOOT_LOG"; then
            booted=true
            echo "  [SUCCESS] System reached login / shell at ${waited}s!"
            break
        fi
    fi

    if (( waited > 0 && waited % 20 == 0 )); then
        echo "  ... waiting for boot (${waited}s elapsed) ..."
    fi

    sleep 2
    waited=$((waited + 2))
done

if [[ "$booted" == true ]]; then
    echo "  Giving 5s for userspace / autologin to settle..."
    sleep 5

    echo "  Injecting systemd-analyze command via QEMU monitor keyboard..."
    python3 - << PYEOF
import socket, time

s = socket.socket(socket.AF_UNIX)
s.settimeout(5)
try:
    s.connect('$MON_SOCK')
    KEY_MAP = {
        'a':'a','b':'b','c':'c','d':'d','e':'e','f':'f','g':'g','h':'h','i':'i','j':'j','k':'k','l':'l','m':'m',
        'n':'n','o':'o','p':'p','q':'q','r':'r','s':'s','t':'t','u':'u','v':'v','w':'w','x':'x','y':'y','z':'z',
        '0':'0','1':'1','2':'2','3':'3','4':'4','5':'5','6':'6','7':'7','8':'8','9':'9',
        '-':'minus','_':'shift-minus','=':'equal','+':'shift-equal',' ':'spc','/':'slash','.':'dot',
        '>':'shift-dot','<':'shift-comma','|':'shift-backslash','\\':'backslash','\n':'ret'
    }
    def type_str(txt):
        for ch in txt:
            k = KEY_MAP.get(ch)
            if k:
                s.sendall(f"sendkey {k}\n".encode())
                time.sleep(0.04)

    # Wake up terminal
    type_str("\n\n")
    time.sleep(1)
    # Output markers and commands to ttyS0
    type_str("echo '===START_SYSTEMD_ANALYZE===' > /dev/ttyS0\n")
    time.sleep(1)
    type_str("systemd-analyze > /dev/ttyS0 2>&1\n")
    time.sleep(2)
    type_str("echo '===START_SYSTEMD_BLAME===' > /dev/ttyS0\n")
    time.sleep(1)
    type_str("systemd-analyze blame | head -n 25 > /dev/ttyS0 2>&1\n")
    time.sleep(2)
    type_str("echo '===END_SYSTEMD_ANALYZE===' > /dev/ttyS0\n")
    time.sleep(2)
    s.close()
    print("  [SUCCESS] Keystrokes sent successfully.")
except Exception as e:
    print(f"  [ERROR] Monitor typing failed: {e}")
PYEOF

    echo "  Waiting 5s for command output to flush..."
    sleep 5
fi

# Clean up QEMU
kill -9 "$QPID" 2>/dev/null || true
wait "$QPID" 2>/dev/null || true
rm -f "$LOCAL_ISO" "$MON_SOCK"

# Copy boot log to shared folder
cp "$BOOT_LOG" "/media/sf_RustOSShare/microverse/out/qemu_${STAGE}_measured.log"
rm -f "$BOOT_LOG"

if grep -q "===START_SYSTEMD_ANALYZE===" "/media/sf_RustOSShare/microverse/out/qemu_${STAGE}_measured.log"; then
    echo "  [SUCCESS] Captured raw systemd-analyze output!"
    sed -n '/===START_SYSTEMD_ANALYZE===/,/===END_SYSTEMD_ANALYZE===/p' "/media/sf_RustOSShare/microverse/out/qemu_${STAGE}_measured.log" > "$RAW_OUT"
    cat "$RAW_OUT"
else
    echo "  [NOTICE] Markers not found directly in ttyS0 log. Checking for Startup finished in log..."
    if grep -E "Startup finished in" "/media/sf_RustOSShare/microverse/out/qemu_${STAGE}_measured.log"; then
        grep -E "Startup finished in" "/media/sf_RustOSShare/microverse/out/qemu_${STAGE}_measured.log" > "$RAW_OUT"
        cat "$RAW_OUT"
    fi
fi

echo "=== [DONE] Benchmark for $STAGE finished ==="
