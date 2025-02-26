
$scriptPath = "C:\Users\wurtzmt\Documents\Coding\PowerShell\PC-Management-Remote\Repair-SCCM\Check-SCCMHealth.ps1" # Path to your script
$bytes = [System.Text.Encoding]::Unicode.GetBytes((Get-Content $scriptPath -Raw))
$encodedCommand = [Convert]::ToBase64String($bytes)

Write-Output $encodedCommand
Write-Output $encodedCommand | Set-Clipboard  # Copies to clipboard
Write-Host "Encoded Command has been copied to clipboard" -ForegroundColor Yellow