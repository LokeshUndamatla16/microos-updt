# Organize MicroVerse Project Files cleanly

$baseDir = "C:\Users\asus\Desktop\RustOSShare"
$desktopDir = "C:\Users\asus\Desktop"
$primaryProjectDir = "C:\Users\asus\Desktop\MicroVerse-Project"

Write-Host "=== Organizing MicroVerse Project ==="

# 1. Create Archive directories in RustOSShare
$archiveDir = Join-Path $baseDir "archive"
$archScreenshots = Join-Path $archiveDir "screenshots"
$archScripts = Join-Path $archiveDir "old_scripts"
$archVdis = Join-Path $archiveDir "legacy_vdis"

New-Item -ItemType Directory -Path $archScreenshots -Force | Out-Null
New-Item -ItemType Directory -Path $archScripts -Force | Out-Null
New-Item -ItemType Directory -Path $archVdis -Force | Out-Null

# 2. Move loose pngs from RustOSShare root to archive/screenshots
Get-ChildItem -Path $baseDir -Filter "*.png" -File | ForEach-Object {
    Move-Item -Path $_.FullName -Destination $archScreenshots -Force
    Write-Host "Archived screenshot: $($_.Name)"
}

# 3. Move loose python test scripts and install_deps.sh to archive/old_scripts
$scriptsToArchive = @("fix_test.py", "install_deps.sh", "measure_single.py", "measure_stages.py", "run_measure.py", "run_measure_bios.py", "setup_ssh.sh", "test_immediate_connect.py", "test_stage1_now.py")
foreach ($s in $scriptsToArchive) {
    $filePath = Join-Path $baseDir $s
    if (Test-Path $filePath) {
        Move-Item -Path $filePath -Destination $archScripts -Force
        Write-Host "Archived script: $s"
    }
}

# 4. Move legacy VDIs (preserve rust-micro-os-v18.vdi which is attached to VM)
Get-ChildItem -Path $baseDir -Filter "*.vdi" -File | Where-Object { $_.Name -ne "rust-micro-os-v18.vdi" } | ForEach-Object {
    Move-Item -Path $_.FullName -Destination $archVdis -Force
    Write-Host "Archived legacy VDI: $($_.Name)"
}

# 5. Move loose markdown lab report
$oldReport = Join-Path $baseDir "RUST_MICRO_OS_LAB_REPORT.md"
if (Test-Path $oldReport) {
    Move-Item -Path $oldReport -Destination $archiveDir -Force
    Write-Host "Archived RUST_MICRO_OS_LAB_REPORT.md"
}

# 6. Build the primary Desktop Project directory
Write-Host "Building primary folder: $primaryProjectDir..."
$subDirs = @(
    "1_Bootable_ISOs",
    "2_Launch_VirtualBox",
    "3_Documentation",
    "4_Scripts_And_Tools",
    "5_Rust_Source",
    "6_Verification_Screenshots"
)

foreach ($sub in $subDirs) {
    New-Item -ItemType Directory -Path (Join-Path $primaryProjectDir $sub) -Force | Out-Null
}

# Copy / create pointers into 1_Bootable_ISOs
$outDir = Join-Path $baseDir "microverse\out"
$isoSub = Join-Path $primaryProjectDir "1_Bootable_ISOs"

# Create Windows shortcuts (.lnk) or copy references
$WshShell = New-Object -ComObject WScript.Shell

$shortcut = $WshShell.CreateShortcut((Join-Path $isoSub "microverse-wifi.iso.lnk"))
$shortcut.TargetPath = Join-Path $outDir "microverse-wifi.iso"
$shortcut.Description = "MicroVerse Wi-Fi and Ethernet Edition (717M)"
$shortcut.Save()

$shortcut = $WshShell.CreateShortcut((Join-Path $isoSub "microverse-final.iso.lnk"))
$shortcut.TargetPath = Join-Path $outDir "microverse-final.iso"
$shortcut.Description = "MicroVerse Official Production Master (687M)"
$shortcut.Save()

$shortcut = $WshShell.CreateShortcut((Join-Path $isoSub "microverse-small.iso.lnk"))
$shortcut.TargetPath = Join-Path $outDir "microverse-small.iso"
$shortcut.Description = "MicroVerse Optimized Stripped Edition (397M)"
$shortcut.Save()

Copy-Item -Path (Join-Path $outDir "SHA256SUMS") -Destination (Join-Path $isoSub "SHA256SUMS.txt") -Force

# 2_Launch_VirtualBox
$vbSub = Join-Path $primaryProjectDir "2_Launch_VirtualBox"
Copy-Item -Path (Join-Path $desktopDir "Start-MicroVerse-OS.bat") -Destination (Join-Path $vbSub "Start-MicroVerse-OS.bat") -Force

# 3_Documentation
$docSub = Join-Path $primaryProjectDir "3_Documentation"
$docFiles = @("README.md", "STATUS.md", "TEST_REPORT.md", "BOOT_TIMES.md", "PRESENTATION.md", "SIZE_REPORT.md")
foreach ($doc in $docFiles) {
    $src = Join-Path $baseDir "microverse\$doc"
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $docSub -Force
    }
}

# 4_Scripts_And_Tools
$toolSub = Join-Path $primaryProjectDir "4_Scripts_And_Tools"
$toolFiles = @("flash.sh", "make-persistent-usb.sh", "hwcheck.sh", "setup_user_vm.ps1")
foreach ($tool in $toolFiles) {
    $src = Join-Path $baseDir "microverse\scripts\$tool"
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $toolSub -Force
    }
}

# 5_Rust_Source
$rustSub = Join-Path $primaryProjectDir "5_Rust_Source"
$rustSrc = Join-Path $baseDir "microverse\rust"
if (Test-Path $rustSrc) {
    Copy-Item -Path $rustSrc -Destination $rustSub -Recurse -Force
}

# 6_Verification_Screenshots
$shotSub = Join-Path $primaryProjectDir "6_Verification_Screenshots"
$shotSrc = Join-Path $baseDir "microverse\screenshots"
if (Test-Path $shotSrc) {
    Copy-Item -Path "$shotSrc\*" -Destination $shotSub -Force
}

Write-Host "Organization complete."
