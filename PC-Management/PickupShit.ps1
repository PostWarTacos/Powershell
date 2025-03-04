<#
#   Intent: Removes old and/or temporary files/folders to save potentially 30GB of space. 
#   Date 25-Feb-25
#>>

param(
    [switch]$resetBase  # Optional switch to include /resetbase in DISM cleanup
)

# Ensure the script is run with administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator. Please re-run with elevated privileges."
    exit
}

# Clear Temp Files
Write-Host "Deleting Temporary Files..." -ForegroundColor Yellow
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clear Windows Update Cache
Write-Host "Cleaning Windows Update Cache..." -ForegroundColor Yellow
Stop-Service wuauserv -Force
Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service wuauserv

# Empty Recycle Bin
Write-Host "Emptying Recycle Bin..." -ForegroundColor Yellow
$shell = New-Object -ComObject Shell.Application
$shell.Namespace(10).Items() | ForEach-Object { $_.InvokeVerb("Delete") }

# Delete Prefetch Files
Write-Host "Cleaning Prefetch Files..." -ForegroundColor Yellow
Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue

# Delete Thumbnails
Write-Host "Clearing Thumbnails Cache..." -ForegroundColor Yellow
Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue

# Delete Windows Error Reports
Write-Host "Removing Old Windows Error Reports..." -ForegroundColor Yellow
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue

# Delete Windows.old if it exists
if (Test-Path "C:\Windows.old") {
    Write-Host "Removing Windows.old (Old Windows Installation)..." -ForegroundColor Yellow
    Remove-Item -Path "C:\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "No Windows.old found, skipping..." -ForegroundColor Green
}

# Clear Old Driver Packages
 Write-Host "Removing Old Driver Packages...(UNDER CONSTRUCTION)" -ForegroundColor Yellow
<#
 pnputil /enum-drivers | ForEach-Object {
    if ($_ -match "Published Name : (oem\d+\.inf)") {
        pnputil /delete-driver $matches[1] /uninstall /force
    }
}
#>

# Run Disk Cleanup silently for System Files
Write-Host "Running Disk Cleanup..." -ForegroundColor Yellow
Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/verylowdisk" -NoNewWindow -Wait

# Run DISM for Windows Component Cleanup
Write-Host "Running DISM Cleanup..." -ForegroundColor Cyan
if ($resetBase) {
    Write-Host "Including /resetbase (Permanent Cleanup)" -ForegroundColor Yellow
    dism /online /cleanup-image /startcomponentcleanup /resetbase
} else {
    Write-Host "Skipping /resetbase (Retaining Rollback Option)" -ForegroundColor Green
    dism /online /cleanup-image /startcomponentcleanup
}

Write-Host "Cleanup Completed!" -ForegroundColor Green

# Displaying DISM features that can be manually removed.
Write-host "Running DISM Features Cleanup."
DISM /online /get-features | more
Write-Host "Select the features to remove and run the following command:" -ForegroundColor Cyan
Write-Host "DISM /online /disable-feature /featurename:<featurename> /remove" -ForegroundColor Cyan

