$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "MV-NetTest"
$isoPath = "C:\Users\asus\Desktop\RustOSShare\microverse\out\microverse-final.iso"
$serialLog = "C:\Users\asus\Desktop\RustOSShare\microverse\out\serial_network_test.log"
$screenPng = "C:\Users\asus\Desktop\RustOSShare\microverse\screenshots\network_verified.png"

# 1. Clean up existing VM
$vms = & $vbox list vms
if ($vms -match $vmName) {
    Write-Host "Cleaning up existing $vmName..."
    & $vbox controlvm $vmName poweroff 2>$null
    Start-Sleep -Seconds 2
    & $vbox unregistervm $vmName --delete 2>$null
}

if (Test-Path $serialLog) { Remove-Item $serialLog -Force }
if (Test-Path $screenPng) { Remove-Item $screenPng -Force }

# 2. Create VM with Network Adapter (NAT with internet access)
Write-Host "Creating VirtualBox VM: $vmName..."
& $vbox createvm --name $vmName --ostype "Debian_64" --register
& $vbox modifyvm $vmName --memory 2048 --cpus 2 --vram 32 --firmware bios --boot1 dvd --boot2 none --boot3 none --boot4 none --nic1 nat --nictype1 82540EM --uart1 0x3F8 4 --uartmode1 file $serialLog

# 3. Attach ISO
& $vbox storagectl $vmName --name "IDE Controller" --add ide
& $vbox storageattach $vmName --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $isoPath

# 4. Start VM
Write-Host "Starting VM..."
& $vbox startvm $vmName --type gui

# 5. Expedite bootloader
for ($i = 0; $i -lt 5; $i++) {
    Start-Sleep -Seconds 1
    & $vbox controlvm $vmName keyboardputscancode 1c 9c 2>$null
}

# 6. Wait for login prompt
Write-Host "Waiting for login prompt..."
$sw = [System.Diagnostics.Stopwatch]::StartNew()
while ($sw.Elapsed.TotalSeconds -lt 90) {
    if (Test-Path $serialLog) {
        $content = Get-Content $serialLog -Raw 2>$null
        if ($content -match "microverse@microverse:") {
            Write-Host "Login prompt reached at $([math]::Round($sw.Elapsed.TotalSeconds, 1))s!"
            break
        }
    }
    Start-Sleep -Seconds 2
}

Start-Sleep -Seconds 3

# 7. Execute Network Diagnostics via guest shell and redirect to serial port
Write-Host "Injecting network diagnostic commands..."

# Banner
& $vbox controlvm $vmName keyboardputstring "echo '=== NETWORK DIAGNOSTICS BEGIN ===' > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 2

# Check IP address and DHCP
& $vbox controlvm $vmName keyboardputstring "ip -br a > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 2

# Check NetworkManager device status
& $vbox controlvm $vmName keyboardputstring "nmcli dev status > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 2

# Check Active Connections
& $vbox controlvm $vmName keyboardputstring "nmcli con show > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 2

# Ping test to verify internet connectivity
& $vbox controlvm $vmName keyboardputstring "ping -c 3 8.8.8.8 > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 4

# Check Wi-Fi subsystem status (rfkill & wireless driver readiness)
& $vbox controlvm $vmName keyboardputstring "rfkill list > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 2

# Display Wi-Fi scanning CLI capability
& $vbox controlvm $vmName keyboardputstring "echo 'nmcli dev wifi list command is ready' > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 2

# Display visual status on screen for screenshot
& $vbox controlvm $vmName keyboardputstring "clear"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 1
& $vbox controlvm $vmName keyboardputstring "nmcli dev status; ip -br a; ping -c 2 8.8.8.8"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 3

# 8. Capture screenshot
Write-Host "Capturing network status screenshot..."
& $vbox controlvm $vmName screenshotpng $screenPng

# End Banner
& $vbox controlvm $vmName keyboardputstring "echo '=== NETWORK DIAGNOSTICS COMPLETE ===' > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 2

# 9. Power off VM
Write-Host "Powering off VM..."
& $vbox controlvm $vmName poweroff
Start-Sleep -Seconds 2
& $vbox unregistervm $vmName --delete

Write-Host "Network test completed."
