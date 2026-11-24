# MicroVerse OS - Official Academic & Instructor Demonstration Guide

## 1. Project Master Directory
All files, bootable ISOs, scripts, documentation, Rust kernel sources, and verification proof are consolidated in one master folder:
> **Location:** `C:\Users\asus\Desktop\MicroVerse-Project`

### Directory Architecture:
- **`1_Bootable_ISOs/`**:
  - `microverse-wifi.iso` (717 MB): High-speed Wi-Fi, Ethernet, and Graphical Desktop OS.
  - `microverse-final.iso` (687 MB): Clean base OS.
  - `SHA256SUMS.txt`: Cryptographic checksums.
- **`2_Launch_VirtualBox/`**:
  - `Start-MicroVerse-OS.bat`: 1-Click launcher to boot or resume the OS in VirtualBox GUI.
  - `Save-And-Exit-MicroVerse-OS.bat`: 1-Click freeze/save session state.
  - `MicroVerse-OS.vbox`: VirtualBox virtual machine definition file.
- **`3_Documentation/`**:
  - `ARCHITECTURE.md`: Hybrid microkernel & Linux subsystem architecture.
  - `BOOT_TIMES.md`: Boot performance benchmarks.
  - `PRESENTATION.md`: Presentation slides and talking points for the review committee.
  - `SIZE_REPORT.md`: Granular storage and component size breakdown.
  - `STATUS.md`: Full checklist of all academic requirements met.
  - `TEST_REPORT.md`: Hardware compatibility, network, and regression test results.
- **`4_Scripts_And_Tools/`**:
  - `hwcheck.sh`: Automated hardware audit and kernel log inspector.
  - `flash.sh` & `make-persistent-usb.sh`: USB flashing scripts with persistence support.
- **`5_Rust_Source/`**:
  - Complete Rust kernel and telemetry source code (`Cargo.toml`, `src/main.rs`).
- **`6_Verification_Screenshots/`**:
  - Complete photo evidence of Desktop, Wi-Fi Manager, Snap Store, and Kernel Telemetry.

---

## 2. Step-by-Step Instructor Demonstration

### Step 1: Launch MicroVerse OS
1. Double-click `Start-MicroVerse-OS.bat` inside `C:\Users\asus\Desktop\MicroVerse-Project\2_Launch_VirtualBox\`.
2. The VirtualBox window appears instantly.
3. The custom Windows-like desktop loads with:
   - High-tech **MicroVerse OS** custom wallpaper with glowing radial core and tech grid.
   - 5 desktop icons: **File Manager**, **Terminal**, **Kernel Telemetry**, **Snap Store**, **Wi-Fi Manager**.
   - Bottom taskbar with Start Menu, Application switcher, System Tray, and Clock.

### Step 2: Demonstrate Wi-Fi & Ethernet Networking
1. Double-click the **Wi-Fi Manager** icon on the desktop.
2. The **MicroVerse Wi-Fi Control Center** window opens:
   - Shows **Ethernet (enp0s3)**: IP assigned via DHCP (`10.0.2.15`), Online & Active.
   - Shows **Wi-Fi Radio (wlan0)**: Dual-radio simulated hardware (`mac80211_hwsim`).
   - Shows **Campus Hotspot (wlan1)**: Broadcasting `Campus_HighSpeed_WiFi`.
   - Displays live scan table: `Campus_HighSpeed_WiFi`, 130 Mbit/s, Signal 100%, 4 bars (`****`), WPA2/WPA3.
3. Press `4` to run a live Latency & Internet Ping Test to Google DNS (`8.8.8.8`) with 0% packet loss.
4. Press `1` to quick-connect to `Campus_HighSpeed_WiFi`.

### Step 3: Demonstrate Canonical Snap Store Integration
1. Double-click the **Snap Store** icon on the desktop.
2. The **MicroVerse Application Snap Store** opens:
   - Shows integrated Canonical Snapd engine connected to the official Ubuntu/Canonical Snap ecosystem.
   - Press `1` to view Featured Software: Visual Studio Code, Spotify, VLC, Chromium, Rust, Docker, and Htop.
   - Press `3` to view installed snaps: Displays `core` (Canonical core runtime) and `hello-world`.
   - Press `4` to run 1-click execution test of `hello-world` verifying sandbox execution!

### Step 4: Demonstrate Bare-Metal Rust Kernel & Diagnostics
1. Double-click **Kernel Telemetry** on the desktop.
2. The hardware diagnostics suite audits the virtual machine:
   - CPU Architecture (`x86_64`, Intel virtualization).
   - Display controller (`VMware SVGA II Adapter`, DRM virtual display).
   - Audio controller (`Intel 82801AA-ICH` ALSA audio).
   - Wireless chipsets & kernel drivers.
   - Confirms zero missing firmware errors in kernel logs!

### Step 5: Session Persistence & Instant Freeze
1. When finished, double-click `Save-And-Exit-MicroVerse-OS.bat`.
2. VirtualBox freezes the VM RAM state directly to disk.
3. When re-opened with `Start-MicroVerse-OS.bat`, the session resumes in **under 1 second** exactly where you left off!

---

## 3. GitHub Repository Synchronization
The code, documentation, and screenshots are organized at:
> **Staging Path:** `C:\Users\asus\Desktop\microos_git_repo`
> **Target GitHub URL:** `https://github.com/LokeshUndamatla16/microos.git`
