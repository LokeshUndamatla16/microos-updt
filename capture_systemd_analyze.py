#!/usr/bin/env python3
import sys
import os
import time
import subprocess
import socket

OVMF_PATH = "/usr/share/ovmf/OVMF.fd"
if not os.path.exists(OVMF_PATH):
    OVMF_PATH = "/usr/share/OVMF/OVMF_CODE_4M.fd"

def measure_iso(iso_path, stage_name, mode="UEFI", timeout=420):
    print(f"\n{'='*70}")
    print(f"[BENCHMARK] Starting {stage_name} ({mode} mode) on {iso_path}")
    print(f"{'='*70}")

    sock_path = f"/tmp/serial_{stage_name}_{mode}.sock"
    mon_sock_path = f"/tmp/mon_{stage_name}_{mode}.sock"
    log_file = f"/media/sf_RustOSShare/microverse/out/qemu_analyze_{stage_name}_{mode}.log"

    for p in [sock_path, mon_sock_path]:
        if os.path.exists(p):
            try:
                os.remove(p)
            except Exception:
                pass

    # Copy ISO to fast /tmp if not already there, or use directly
    qemu_cmd = [
        "nice", "-n", "10",
        "qemu-system-x86_64",
        "-m", "1024",
        "-smp", "2",
        "-vga", "std",
        "-display", "none",
        "-device", "virtio-rng-pci",
        "-device", "qemu-xhci",
        "-device", "usb-storage,drive=usb,bootindex=1",
        "-drive", f"if=none,id=usb,format=raw,readonly=on,file={iso_path}",
        "-netdev", "user,id=net0",
        "-device", "virtio-net-pci,netdev=net0",
        "-chardev", f"socket,id=char0,path={sock_path},server=on,wait=off,logfile={log_file}",
        "-serial", "chardev:char0",
        "-monitor", f"unix:{mon_sock_path},server=on,wait=off",
        "-no-reboot"
    ]

    if mode == "UEFI":
        qemu_cmd.extend(["-bios", OVMF_PATH])

    print(f"[INFO] Spawning QEMU with: {' '.join(qemu_cmd)}")
    proc = subprocess.Popen(qemu_cmd, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Wait 2s for monitor socket then send Enter key to skip bootloader countdown
    time.sleep(2)
    for _ in range(5):
        if os.path.exists(mon_sock_path):
            try:
                ms = socket.socket(socket.AF_UNIX)
                ms.connect(mon_sock_path)
                ms.sendall(b"sendkey ret\n")
                ms.close()
                print("[INFO] Sent Enter key via QEMU monitor to expedite bootloader.")
                break
            except Exception:
                time.sleep(0.5)

    # Connect to serial socket
    serial_s = socket.socket(socket.AF_UNIX)
    connected = False
    for _ in range(20):
        if os.path.exists(sock_path):
            try:
                serial_s.connect(sock_path)
                serial_s.setblocking(False)
                connected = True
                print("[INFO] Connected to QEMU guest serial console socket.")
                break
            except Exception:
                time.sleep(0.5)
        else:
            time.sleep(0.5)

    if not connected:
        print("[ERROR] Failed to connect to serial socket.")
        proc.kill()
        return None

    start_time = time.time()
    last_report = 0
    buffer = ""
    state = "WAIT_BOOT"
    captured_output = ""

    while time.time() - start_time < timeout:
        if proc.poll() is not None:
            print("[INFO] QEMU process exited.")
            break

        try:
            chunk = serial_s.recv(4096).decode("utf-8", errors="replace")
            if chunk:
                buffer += chunk
        except BlockingIOError:
            pass

        elapsed = int(time.time() - start_time)
        if elapsed - last_report >= 30:
            last_report = elapsed
            print(f"  [QEMU] {elapsed}s elapsed (state: {state})...")

        if state == "WAIT_BOOT":
            # Check for login prompt or bash shell or Startup finished
            if "login:" in buffer or "microverse@" in buffer or "$ " in buffer or "Linux debian" in buffer or "mv-info" in buffer:
                print(f"[SUCCESS] Reached login/shell state at {elapsed}s!")
                time.sleep(2)
                if "login:" in buffer and "microverse@" not in buffer:
                    serial_s.sendall(b"microverse\n")
                    state = "WAIT_PASSWORD"
                else:
                    state = "SEND_COMMANDS"

        elif state == "WAIT_PASSWORD":
            if "Password:" in buffer:
                time.sleep(1)
                serial_s.sendall(b"live\n")
                state = "WAIT_PROMPT"
            elif "microverse@" in buffer or "$ " in buffer:
                state = "SEND_COMMANDS"

        elif state == "WAIT_PROMPT":
            if "microverse@" in buffer or "$ " in buffer:
                state = "SEND_COMMANDS"

        elif state == "SEND_COMMANDS":
            time.sleep(2)
            print("[INFO] Injecting 'systemd-analyze' commands...")
            cmd = (
                b"\n"
                b"echo '===START_RAW_ANALYZE==='\n"
                b"systemd-analyze\n"
                b"echo '===START_RAW_BLAME==='\n"
                b"systemd-analyze blame | head -n 25\n"
                b"echo '===END_RAW_ANALYZE==='\n"
            )
            serial_s.sendall(cmd)
            state = "WAIT_OUTPUT"

        elif state == "WAIT_OUTPUT":
            if "===END_RAW_ANALYZE===" in buffer:
                print(f"[SUCCESS] Captured raw systemd-analyze output in {elapsed}s!")
                captured_output = buffer
                time.sleep(1)
                serial_s.sendall(b"sudo poweroff\n")
                time.sleep(3)
                break

        time.sleep(1)

    try:
        proc.terminate()
        proc.wait(timeout=5)
    except Exception:
        proc.kill()

    for p in [sock_path, mon_sock_path]:
        if os.path.exists(p):
            try:
                os.remove(p)
            except Exception:
                pass

    return captured_output

if __name__ == "__main__":
    target_iso = sys.argv[1] if len(sys.argv) > 1 else "/media/sf_RustOSShare/microverse/out/stage1.iso"
    stage = sys.argv[2] if len(sys.argv) > 2 else "stage1"
    mode = sys.argv[3] if len(sys.argv) > 3 else "UEFI"
    out = measure_iso(target_iso, stage, mode)
    if out and "===START_RAW_ANALYZE===" in out:
        part = out.split("===START_RAW_ANALYZE===")[1].split("===END_RAW_ANALYZE===")[0].strip()
        print("\n" + "="*70)
        print(f"RAW UNEDITED SYSTEMD-ANALYZE OUTPUT ({stage.upper()} - {mode}):")
        print("="*70)
        print(part)
        print("="*70)
        with open(f"/media/sf_RustOSShare/microverse/out/systemd_raw_{stage}_{mode}.txt", "w") as f:
            f.write(part + "\n")
    else:
        print(f"[FAIL] Could not capture complete systemd-analyze markers for {stage}")
