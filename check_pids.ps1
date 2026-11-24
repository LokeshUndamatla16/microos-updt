Get-Process | Where-Object { $_.ProcessName -like "*VirtualBox*" } | Select-Object Id, ProcessName, MainWindowTitle | Format-Table -AutoSize
