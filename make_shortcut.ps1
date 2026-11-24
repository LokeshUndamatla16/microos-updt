$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("C:\Users\asus\Desktop\Run-MicroVerse-OS.lnk")
$Shortcut.TargetPath = "C:\Program Files\Oracle\VirtualBox\VirtualBoxVM.exe"
$Shortcut.Arguments = '--startvm "MicroVerse OS"'
$Shortcut.IconLocation = "C:\Program Files\Oracle\VirtualBox\VirtualBox.exe,0"
$Shortcut.Description = "Start MicroVerse OS in VirtualBox"
$Shortcut.Save()
Write-Host "Created Desktop shortcut: Run-MicroVerse-OS.lnk"
