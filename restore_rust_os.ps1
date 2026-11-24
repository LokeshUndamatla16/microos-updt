$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

# 1. Poweroff if running
& $vbox controlvm "Rust Micro OS" poweroff 2>$null
& $vbox controlvm "MicroVerse OS" poweroff 2>$null
Start-Sleep -Seconds 2

# 2. Configure Rust Micro OS to boot its original pure Rust v18 VDI hard disk
& $vbox storageattach "Rust Micro OS" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium emptydrive
& $vbox modifyvm "Rust Micro OS" --boot1 disk --boot2 none --boot3 none --boot4 none --firmware EFI --defaultfrontend gui

# 3. Create a clean shortcut for Rust Micro OS on desktop
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("C:\Users\asus\Desktop\Run-Rust-Micro-OS.lnk")
$Shortcut.TargetPath = "C:\Program Files\Oracle\VirtualBox\VirtualBoxVM.exe"
$Shortcut.Arguments = '--startvm "Rust Micro OS"'
$Shortcut.IconLocation = "C:\Program Files\Oracle\VirtualBox\VirtualBox.exe,0"
$Shortcut.Description = "Start Rust Micro OS (Bare Metal Rust Kernel)"
$Shortcut.Save()

Write-Host "Configured Rust Micro OS successfully."
