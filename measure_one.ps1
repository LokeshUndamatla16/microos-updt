param(
    [string]$isoPath,
    [string]$firmware,       # "bios" or "efi"
    [string]$testName,       # e.g. "final_bios"
    [string]$serialLog,
    [string]$screenPng
)

$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "MV-Test-$testName"

# 1. Clean up if exists
$vms = & $vbox list vms
if ($vms -match $vmName) {
    Write-Host "[$testName] Cleaning up existing VM: $vmName..."
    & $vbox controlvm $vmName poweroff 2>$null
    Start-Sleep -Seconds 2
    & $vbox unregistervm $vmName --delete 2>$null
}

if (Test-Path $serialLog) { Remove-Item $serialLog -Force }
if (Test-Path $screenPng) { Remove-Item $screenPng -Force }

# 2. Create VM
Write-Host "[$testName] Creating VM: $vmName (Firmware: $firmware)..."
& $vbox createvm --name $vmName --ostype "Debian_64" --register
& $vbox modifyvm $vmName --memory 2048 --cpus 2 --vram 32 --firmware $firmware --boot1 dvd --boot2 none --boot3 none --boot4 none --nic1 nat --uart1 0x3F8 4 --uartmode1 file $serialLog

# 3. Attach Storage
& $vbox storagectl $vmName --name "IDE Controller" --add ide
& $vbox storageattach $vmName --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $isoPath

# 4. Start VM
Write-Host "[$testName] Starting VM with GUI..."
& $vbox startvm $vmName --type gui

# 5. Expedite Bootloader (pass any "Press any key" or boot menu prompt)
for ($i = 0; $i -lt 8; $i++) {
    Start-Sleep -Milliseconds 600
    & $vbox controlvm $vmName keyboardputscancode 1c 9c 2>$null
    & $vbox controlvm $vmName keyboardputscancode 39 b9 2>$null
}

# 6. Monitor Serial Log for completion (Timeout: 240 seconds)
Write-Host "[$testName] Polling for boot completion in serial log..."
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$booted = $false

while ($sw.Elapsed.TotalSeconds -lt 240) {
    if (Test-Path $serialLog) {
        $content = Get-Content $serialLog -Raw 2>$null
        if ($content -match "microverse@microverse:" -or $content -match "microverse login:") {
            $booted = $true
            Write-Host "[$testName] System reached login prompt at $([math]::Round($sw.Elapsed.TotalSeconds, 1))s!"
            break
        }
    }
    Start-Sleep -Seconds 1
}

if (-not $booted) {
    Write-Host "[$testName] Warning: Login prompt not detected within 240s. Checking log..."
}

# 7. Settle userspace
Start-Sleep -Seconds 4

# 8. Send commands to guest to output systemd-analyze, blame, and mv-info to serial port
Write-Host "[$testName] Injecting commands to guest shell..."
& $vbox controlvm $vmName keyboardputstring "systemd-analyze > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 3

& $vbox controlvm $vmName keyboardputstring "systemd-analyze blame | head -n 15 > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 3

& $vbox controlvm $vmName keyboardputstring "mv-info > /dev/ttyS0"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 3

# 9. Also print systemd-analyze to screen for the screenshot
& $vbox controlvm $vmName keyboardputstring "systemd-analyze"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 2

# 10. Take Screenshot
Write-Host "[$testName] Capturing screenshot to $screenPng..."
& $vbox controlvm $vmName screenshotpng $screenPng

# 11. Shut down VM
Write-Host "[$testName] Powering off VM..."
& $vbox controlvm $vmName poweroff
Start-Sleep -Seconds 2
& $vbox unregistervm $vmName --delete

Write-Host "[$testName] Run completed successfully."
