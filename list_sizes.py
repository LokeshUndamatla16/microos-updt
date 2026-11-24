#!/usr/bin/env python3
import subprocess
import os

chroot_dir = "/root/microverse_work/chroot"
dpkg_status = os.path.join(chroot_dir, "var/lib/dpkg/status")

packages = []
current_pkg = {}
with open(dpkg_status, "r", encoding="utf-8", errors="replace") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line:
            if "Package" in current_pkg and "Installed-Size" in current_pkg:
                try:
                    packages.append((int(current_pkg["Installed-Size"]), current_pkg["Package"]))
                except ValueError:
                    pass
            current_pkg = {}
        elif line.startswith("Package: "):
            current_pkg["Package"] = line[9:].strip()
        elif line.startswith("Installed-Size: "):
            current_pkg["Installed-Size"] = line[16:].strip()

packages.sort(key=lambda x: x[0], reverse=True)

print("=== TOP 20 LARGEST PACKAGES ===")
for size_kb, pkg in packages[:20]:
    size_mb = size_kb / 1024.0
    print(f"{size_mb:8.2f} MB  {pkg}")
