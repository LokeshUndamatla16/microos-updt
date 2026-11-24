$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
& $vbox modifyvm 2>&1 | Select-String "firmware"
