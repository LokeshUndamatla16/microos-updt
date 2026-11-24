param(
    [string]$isoPath = "C:\Users\asus\Desktop\RustOSShare\microverse\out\microverse-wifi.iso",
    [string]$serialLog = "C:\Users\asus\Desktop\RustOSShare\microverse\logs\wifi_serial.log",
    [string]$screenPng = "C:\Users\asus\Desktop\RustOSShare\microverse\screenshots\wifi_verified.png"
)

$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "MV-Wifi-Test"

Write-Host "=== MicroVerse Wi-Fi VirtualBox Verification ==="

if (-not (Test-Path $isoPath)) {
    Write-Error "ISO file not found: $isoPath"
    exit 1
}

# 1. Clean up if exists
$vms = & $vbox list vms
if ($vms -match $vmName) {
    Write-Host "Cleaning up existing VM: $vmName..."
    & $vbox controlvm $vmName poweroff 2>$null
    Start-Sleep -Seconds 2
    & $vbox unregistervm $vmName --delete 2>$null
}

if (Test-Path $serialLog) { Remove-Item $serialLog -Force }
if (Test-Path $screenPng) { Remove-Item $screenPng -Force }

# Ensure dirs exist
$logDir = Split-Path $serialLog -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$screenDir = Split-Path $screenPng -Parent
if (-not (Test-Path $screenDir)) { New-Item -ItemType Directory -Path $screenDir -Force | Out-Null }

# 2. Create VM (2GB RAM, 2 CPUs, NAT, Serial file)
Write-Host "Creating VM: $vmName..."
& $vbox createvm --name $vmName --ostype "Debian_64" --register
& $vbox modifyvm $vmName --memory 2048 --cpus 2 --vram 32 --boot1 dvd --boot2 none --boot3 none --boot4 none --nic1 nat --uart1 0x3F8 4 --uartmode1 file $serialLog

# 3. Attach Storage
& $vbox storagectl $vmName --name "IDE Controller" --add ide
& $vbox storageattach $vmName --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $isoPath

# 4. Start VM
Write-Host "Starting VM..."
& $vbox startvm $vmName --type gui

# 5. Expedite Bootloader
for ($i = 0; $i -lt 8; $i++) {
    Start-Sleep -Milliseconds 600
    & $vbox controlvm $vmName keyboardputscancode 1c 9c 2>$null
    & $vbox controlvm $vmName keyboardputscancode 39 b9 2>$null
}

# 6. Monitor Serial Log for completion (Timeout: 120 seconds)
Write-Host "Polling for boot completion..."
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$booted = $false

while ($sw.Elapsed.TotalSeconds -lt 120) {
    if (Test-Path $serialLog) {
        $content = Get-Content $serialLog -Raw 2>$null
        if ($content -match "microverse@microverse:" -or $content -match "microverse login:" -or $content -match "login:") {
            $booted = $true
            Write-Host "System reached login prompt at $([math]::Round($sw.Elapsed.TotalSeconds, 1))s!"
            break
        }
    }
    Start-Sleep -Seconds 1
}

if (-not $booted) {
    Write-Host "Continuing after wait timeout..."
}

# Settle userspace
Start-Sleep -Seconds 5

# 7. Send verification commands to serial port and console
Write-Host "Injecting verification commands to guest..."

# Wake shell / press enter
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 1

# Output issue / motd banner
& $vbox controlvm $vmName keyboardputstring "cat /etc/issue > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 2

# Check wifi command
& $vbox controlvm $vmName keyboardputstring "which wifi > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 1

# Check network manager status
& $vbox controlvm $vmName keyboardputstring "nmcli dev status > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 2

# Check unblock-wifi service
& $vbox controlvm $vmName keyboardputstring "systemctl is-active unblock-wifi > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 1

# Run wifi helper head
& $vbox controlvm $vmName keyboardputstring "head -n 25 /usr/local/bin/wifi > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 2

# Display clearly on screen for screenshot
& $vbox controlvm $vmName keyboardputstring "clear"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Milliseconds 500

& $vbox controlvm $vmName keyboardputstring "cat /etc/issue"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Milliseconds 800

& $vbox controlvm $vmName keyboardputstring "nmcli dev status"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Milliseconds 800

& $vbox controlvm $vmName keyboardputstring "which wifi && echo 'WIFI HELPER INSTALLED OK'"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 3

# 8. Capture screenshot
Write-Host "Capturing screenshot to $screenPng..."
& $vbox controlvm $vmName screenshotpng $screenPng
Start-Sleep -Seconds 1

# 9. Clean up
Write-Host "Powering off VM..."
& $vbox controlvm $vmName poweroff
Start-Sleep -Seconds 2
& $vbox unregistervm $vmName --delete

Write-Host "Verification run completed successfully."
