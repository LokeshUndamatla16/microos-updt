$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "MicroVerse OS"

Write-Host "Installing graphical desktop (LXDE) in MicroVerse OS..."
& $vbox controlvm $vmName keyboardputstring "sudo apt-get install -y --no-install-recommends xserver-xorg xinit lxde-core lightdm lightdm-gtk-greeter"
& $vbox controlvm $vmName keyboardputscancode 1c 9c
