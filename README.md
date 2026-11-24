# MicroVerse Live OS: Portable x86_64 Live USB System

**MicroVerse** is a Debian 12 (bookworm) live operating system engineered to boot on **any** x86_64 computer (desktop or laptop) in both modern **UEFI** and legacy **BIOS** mode without touching or installing anything to the computer's internal disks.

---

## 1. Flashing MicroVerse to a USB Flash Drive

To boot on real hardware, write `microverse-final.iso` (or any `stageN.iso`) to a USB flash drive (minimum 2 GB).

### Option A: Linux Terminal (`flash.sh` or `dd`)
MicroVerse includes a safe flashing utility with built-in system disk guards:
```bash
sudo ./scripts/flash.sh ./out/microverse-final.iso /dev/sdX
```
Or use raw `dd`:
```bash
sudo dd if=./out/microverse-final.iso of=/dev/sdX bs=4M status=progress oflag=sync conv=fsync
```
*(Replace `/dev/sdX` with your target USB drive name. Never write to `/dev/sda` if it contains your operating system).*

### Option B: Windows (Rufus)
1. Download and run [Rufus](https://rufus.ie/).
2. Insert your USB drive and select `microverse-final.iso`.
3. Partition scheme: **MBR** or **GPT**.
4. Target system: **BIOS or UEFI**.
5. Click **START**.
6. **CRITICAL STEP:** Rufus will pop up a prompt asking for "ISOHybrid image detected". You **MUST** select:
   > **"Write in DD Image mode"**
   *(Do NOT select ISO mode, as DD mode guarantees the EFI system partition and hybrid MBR boot sectors are written verbatim).*

### Option C: Cross-Platform (balenaEtcher)
1. Open [balenaEtcher](https://etcher.balena.io/).
2. Select `microverse-final.iso` -> Select USB Drive -> Click **Flash!**

### Option D: Multi-Boot (Ventoy)
1. Install [Ventoy](https://www.ventoy.net/) onto your USB drive.
2. Copy `microverse-final.iso` directly into the USB drive partition.

---

## 2. Booting on Another Computer: Boot Menu Keys by Brand

1. Insert the flashed USB drive into the target computer while it is powered off.
2. Power on the computer and immediately begin tapping the **Boot Menu Key** repeatedly until the boot selection menu appears:

| Manufacturer / Brand | Boot Menu Hotkey | BIOS / UEFI Setup Key |
| :--- | :---: | :---: |
| **Dell / Alienware** | **F12** | F2 |
| **HP / Compaq** | **F9** or **Esc** | F10 |
| **Lenovo (ThinkPad, IdeaPad)** | **F12** or **Enter -> F12** | F1 / F2 |
| **ASUS** | **F8** or **Esc** | F2 / Del |
| **Acer** | **F12** | F2 / Del |
| **MSI** | **F11** | Del |
| **Toshiba / Dynabook** | **F12** | F2 |
| **Sony VAIO** | **F11** or **Assist Button** | F2 |
| **Samsung** | **F12** or **Esc** | F2 |
| **Surface (Microsoft)** | **Hold Volume Down + Power** | Volume Up |
| **Apple Mac (Intel x86_64)** | **Hold Option / Alt Key** | Cmd + R |

3. Select your USB drive from the list (often labeled "UEFI: Vendor USB", "USB Storage Device", or your flash drive brand name).

---

## 3. Secure Boot Instructions

MicroVerse includes the official Debian Microsoft-signed **Shim** (`shim-signed`) and **GRUB EFI** (`grub-efi-amd64-signed`). On the vast majority of modern computers, MicroVerse boots with **Secure Boot Enabled** without any intervention.

### When Secure Boot Must Be Disabled:
On certain PC firmware (e.g. older HP machines, custom desktop motherboards with strict Microsoft-only CA keys, or machines with revoked DBX signatures), Secure Boot may block 3rd-party live media with a "Secure Boot Violation" error.

### Exact Steps to Disable Secure Boot:
1. Power on the computer and press the **BIOS Setup Key** (usually `F2`, `Del`, or `F10`).
2. Navigate with arrow keys to the **Security**, **Boot**, or **Authentication** tab.
3. Locate **Secure Boot**:
   - Change setting from **Enabled** to **Disabled**.
4. If the option is greyed out:
   - Set a temporary "Supervisor Password" or "Admin Password" in the Security tab (this unlocks greyed-out Secure Boot options on Acer and Lenovo laptops).
5. Navigate to **Exit** -> **Save Changes and Reset** (or press **F10**).
6. Tap the Boot Menu Key (`F12`, etc.) and boot into MicroVerse.

---

## 4. Boot Options Explained

When MicroVerse starts, the bootloader menu presents four specialized boot targets:

1. **Live (default):**
   Standard live environment with hardware acceleration. Boots into high-resolution framebuffer console with full driver support.
2. **Live (safe graphics: nomodeset):**
   Disables kernel mode setting (`nomodeset`). Use this if you encounter a black screen, garbled graphics, or modern NVIDIA / Intel Arc GPU freezes.
3. **Live (load all to RAM: toram):**
   Copies the entire SquashFS root filesystem into RAM (`tmpfs`) during boot.
   *Benefit:* Once booted, you can unplug and remove the USB flash drive completely, leaving all USB ports free and achieving ultra-fast system responsiveness.
4. **Live with persistence:**
   Activates live persistence mode. Reads and writes changes to an ext4 partition labeled `persistence`. Files, Wi-Fi keys, and installed packages persist across reboots.

---

## 5. Adding USB Persistence

To enable data and package persistence across reboots:
1. Boot into MicroVerse (or run from any Linux terminal with the USB plugged in).
2. Execute the persistence script:
   ```bash
   sudo make-persistent-usb.sh /dev/sdX
   ```
3. The script formats unallocated free space into an ext4 partition labeled `persistence` with `/ union` configuration.
4. On future boots, select **Live with persistence**.

---

## 6. Troubleshooting Guide

| Symptom | Probable Cause | Immediate Solution |
| :--- | :--- | :--- |
| **Black screen / freeze after boot menu** | Proprietary GPU driver conflict | Reboot, select **Live (safe graphics: nomodeset)** in the boot menu. |
| **No Wi-Fi networks discovered** | Missing proprietary wireless firmware | Run `sudo hwcheck.sh` to identify missing firmware. Connect Ethernet or USB tethering, then run `sudo apt update && sudo apt install firmware-linux`. |
| **USB drive not recognized in boot menu** | Flashed in ISO mode instead of DD mode | Re-flash USB using Rufus with **"Write in DD Image mode"** selected, or use `flash.sh`. |
| **System hangs on USB 3.0 / USB-C port** | USB 3.x controller power saving glitch | Plug the USB flash drive into a USB 2.0 (black) port or standard USB Type-A port. |
| **Audio silent or no output** | ALSA volume muted by default | Run `alsamixer`, select your sound card (`F6`), and press `M` on the Master / PCM channel to unmute. |

---

## 7. Default Credentials

- **Username:** `microverse`
- **Password:** `live`
- **Root Password:** `live`
- **Sudo:** Pre-configured with passwordless execution (`sudo <command>`).
