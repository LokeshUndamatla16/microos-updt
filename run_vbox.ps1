$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "MicroVerse-Live"
$iso = "C:\Users\asus\Desktop\RustOSShare\microverse\out\microverse-final.iso"
$serialLog = "C:\Users\asus\Desktop\RustOSShare\microverse\out\vbox_serial.log"

Write-Host "Checking for existing $vmName VM..."
$vms = & $vbox list vms
if ($vms -match "MicroVerse-Live") {
    Write-Host "Powering off and removing existing $vmName..."
    & $vbox controlvm $vmName poweroff
    Start-Sleep -Seconds 2
    & $vbox unregistervm $vmName --delete
}

if (Test-Path $serialLog) {
    Remove-Item -Path $serialLog -Force
}

Write-Host "Creating VirtualBox VM: $vmName..."
& $vbox createvm --name $vmName --ostype "Debian_64" --register
& $vbox modifyvm $vmName --memory 2048 --cpus 2 --vram 32 --firmware bios --boot1 dvd --boot2 none --boot3 none --boot4 none --nic1 nat --uart1 0x3F8 4 --uartmode1 file $serialLog
& $vbox storagectl $vmName --name "IDE Controller" --add ide
& $vbox storageattach $vmName --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $iso

Write-Host "Starting VirtualBox VM with GUI window..."
& $vbox startvm $vmName --type gui

Write-Host "VM launched."
