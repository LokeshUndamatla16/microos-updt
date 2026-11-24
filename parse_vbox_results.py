#!/usr/bin/env python3
import os, re, sys

base_dir = r"C:\Users\asus\Desktop\RustOSShare\microverse"
out_dir = os.path.join(base_dir, "out")
screenshots_dir = os.path.join(base_dir, "screenshots")

tests = [
    {
        "id": "final_bios",
        "iso_name": "microverse-final.iso",
        "iso_path": os.path.join(out_dir, "microverse-final.iso"),
        "firmware": "BIOS (Legacy / Syslinux)",
        "log": os.path.join(out_dir, "serial_final_bios.log"),
        "png": os.path.join(screenshots_dir, "final_bios.png"),
    },
    {
        "id": "final_efi",
        "iso_name": "microverse-final.iso",
        "iso_path": os.path.join(out_dir, "microverse-final.iso"),
        "firmware": "UEFI (EDK2 / GRUB EFI Signed)",
        "log": os.path.join(out_dir, "serial_final_efi.log"),
        "png": os.path.join(screenshots_dir, "final_efi.png"),
    },
    {
        "id": "small_bios",
        "iso_name": "microverse-small.iso",
        "iso_path": os.path.join(out_dir, "microverse-small.iso"),
        "firmware": "BIOS (Legacy / Syslinux)",
        "log": os.path.join(out_dir, "serial_small_bios.log"),
        "png": os.path.join(screenshots_dir, "small_bios.png"),
    },
    {
        "id": "small_efi",
        "iso_name": "microverse-small.iso",
        "iso_path": os.path.join(out_dir, "microverse-small.iso"),
        "firmware": "UEFI (EDK2 / GRUB EFI Signed)",
        "log": os.path.join(out_dir, "serial_small_efi.log"),
        "png": os.path.join(screenshots_dir, "small_efi.png"),
    },
]

print("=== PARSING VIRTUALBOX RAW BENCHMARK RESULTS ===")
for t in tests:
    print(f"\n--- Test: {t['id']} ({t['firmware']}) ---")
    if os.path.exists(t["iso_path"]):
        size_mb = os.path.getsize(t["iso_path"]) / (1024 * 1024)
        print(f"ISO Size: {size_mb:.1f} MiB")
    else:
        print("ISO not found!")

    if os.path.exists(t["log"]):
        with open(t["log"], "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()
        print(f"Log lines: {len(lines)}")
        # Look for systemd-analyze output
        sa_lines = [l.strip() for l in lines if "Startup finished in" in l or "graphical.target" in l]
        if sa_lines:
            for sl in sa_lines:
                print(f"  [RAW] {sl}")
        else:
            # Look for kernel timestamp of login prompt
            login_lines = [l.strip() for l in lines if "login:" in l or "snapd.seeded" in l]
            for ll in login_lines[:3]:
                print(f"  [MARKER] {ll}")
    else:
        print(f"Log not yet generated: {t['log']}")

    if os.path.exists(t["png"]):
        print(f"Screenshot exists: {t['png']} ({os.path.getsize(t['png'])} bytes)")
    else:
        print(f"Screenshot not yet present: {t['png']}")
