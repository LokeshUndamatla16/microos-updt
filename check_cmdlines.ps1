Get-CimInstance Win32_Process | Where-Object { $_.Name -like "*VirtualBox*" } | Select-Object ProcessId, Name, CommandLine | Format-List
