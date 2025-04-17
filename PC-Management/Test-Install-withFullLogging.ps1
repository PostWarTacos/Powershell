# Relaunch in 64-bit PowerShell if currently 32-bit
if (-not [Environment]::Is64BitProcess) {
    Write-Host "Running 32-bit."
    $sysnativePS = "$env:windir\sysnative\WindowsPowerShell\v1.0\powershell.exe"
    Start-Process $sysnativePS -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Wait
    exit
}

# Begin logging
$logPath = "C:\Windows\Temp\Commvault_Install.log"
Start-Transcript -Path $logPath -Append
$VerbosePreference = "Continue"
Write-Host "==== Commvault Install Script Started ===="

# UNINSTALL
$appToRemove = "commvault"
Write-Host "Searching for cached installers matching: $appToRemove"
[array]$cachedInstallers = Get-ChildItem "C:\ProgramData\Package Cache" -Recurse -Exclude *.msi |
    Where-Object { $_.Name -match $appToRemove -or $_.VersionInfo.CompanyName -match $appToRemove } |
    Select-Object -ExpandProperty FullName

foreach ($exe in $cachedInstallers) {
    Write-Host "Uninstalling cached installer: $exe"
    Start-Process $exe -ArgumentList "/silent /uninstall" -Wait -Verbose
}

# INSTALL
$appToInstall = ".\WindowsEndpoint64_Permanent.exe"
Write-Host "Installing Commvault from: $appToInstall"
$proc = Start-Process $appToInstall -ArgumentList "/silent /install" -PassThru -Verbose
$proc.WaitForExit()
Write-Host "Installer exited with code: $($proc.exitcode)"


# MODIFY REGISTRY
$keyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EB6937E8-425B-4FED-B056-3A43613B072F}"
$regName = "Backups"
$regValue = "True"
$timeout = 180
$elapsed = 0
$found = $false

Write-Host "Waiting up to $timeout seconds for registry key to appear: $keyPath"
while (!(Test-Path $keyPath) -and ($elapsed -lt $timeout)) {
    Start-Sleep -Seconds 5
    $elapsed += 5
    Write-Host "Still waiting... ($elapsed seconds elapsed)"
}

if (Test-Path $keyPath) {
    Write-Host "Registry key found. Setting $regName = $regValue"
    Set-ItemProperty -Path $keyPath -Name $regName -Value $regValue -Force -Verbose
    Write-Host "Registry key updated successfully."
} else {
    Write-Warning "Registry key not found after waiting. Could not set value."
}

Write-Host "==== Commvault Install Script Completed ===="
Stop-Transcript
