$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "MicroVerse-Live"
$screenPng = "C:\Users\asus\Desktop\RustOSShare\microverse\out\vbox_screen.png"
$serialLog = "C:\Users\asus\Desktop\RustOSShare\microverse\out\vbox_serial.log"

Write-Host "Sending 'systemd-analyze' command to guest keyboard..."
& $vbox controlvm $vmName keyboardputstring "systemd-analyze"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 3

Write-Host "Sending 'mv-info' command to guest keyboard..."
& $vbox controlvm $vmName keyboardputstring "mv-info"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
Start-Sleep -Seconds 3

Write-Host "Taking fresh VM Screenshot..."
& $vbox controlvm $vmName screenshotpng $screenPng

Write-Host "--- Latest 50 lines from Serial Console Log ---"
if (Test-Path $serialLog) {
    Get-Content $serialLog -Tail 50
}
