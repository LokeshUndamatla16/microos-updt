$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "MicroVerse OS"
$isoPath = "C:\Users\asus\Desktop\RustOSShare\microverse\out\microverse-wifi.iso"

Write-Host "Creating VirtualBox VM: $vmName..."

# Clean up if existing
$vms = & $vbox list vms
if ($vms -match ('"' + $vmName + '"')) {
    Write-Host "Unregistering older $vmName..."
    & $vbox controlvm $vmName poweroff 2>$null
    Start-Sleep -Seconds 1
    & $vbox unregistervm $vmName --delete 2>$null
}

# 1. Create and register VM
& $vbox createvm --name $vmName --ostype "Debian_64" --register

# 2. Configure system specs
& $vbox modifyvm $vmName `
    --memory 2048 `
    --cpus 2 `
    --vram 32 `
    --graphicscontroller vmsvga `
    --boot1 dvd `
    --boot2 none `
    --boot3 none `
    --boot4 none `
    --nic1 nat `
    --nictype1 82540EM `
    --cableconnected1 on `
    --audio-enabled on `
    --audio-controller ac97 `
    --mouse ps2 `
    --keyboard ps2

# 3. Add Storage Controller and attach ISO
& $vbox storagectl $vmName --name "IDE Controller" --add ide
& $vbox storageattach $vmName --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $isoPath

Write-Host "VirtualBox VM '$vmName' successfully configured with '$isoPath'."
