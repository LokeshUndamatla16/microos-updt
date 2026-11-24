$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$baseDir = "C:\Users\asus\Desktop\RustOSShare\microverse"
$screenDir = Join-Path $baseDir "screenshots"
$outDir = Join-Path $baseDir "out"

if (-not (Test-Path $screenDir)) {
    New-Item -ItemType Directory -Path $screenDir -Force | Out-Null
}

# Clean up any leftover MicroVerse test VMs
$vms = & $vbox list vms
foreach ($line in $vms) {
    if ($line -match '"(MicroVerse-[^"]+)"') {
        $name = $matches[1]
        Write-Host "Found leftover VM: $name, shutting down..."
        & $vbox controlvm $name poweroff 2>$null
        Start-Sleep -Seconds 2
        & $vbox unregistervm $name --delete 2>$null
    }
}
Write-Host "Cleanup complete."
