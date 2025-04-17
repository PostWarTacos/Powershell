# UNINSTALL
$appToRemove = "commvault"
[array]$cachedInstallers = Get-ChildItem "C:\ProgramData\Package Cache" -Recurse -Exclude *.msi | 
    Where-Object { $_.Name -match $appToRemove -or $_.VersionInfo.CompanyName -match $appToRemove } |
    Select-Object -ExpandProperty FullName
foreach( $exe in $cachedInstallers ){
    Start-Process $exe -ArgumentList "/silent /uninstall" -wait
}

# INSTALL
$appToInstall = ".\WindowsEndpoint64_Permanent.exe"
Start-Process $appToInstall -ArgumentList "/silent /install" -Wait
# start /wait cmd /c ".\WindowsEndpoint64_Permanent.exe /silent /install"

# SLEEP and ADD KEY
Start-Sleep -Seconds 300
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EB6937E8-425B-4FED-B056-3A43613B072F}" -Name "Backups" -Value "True" -Force
# REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EB6937E8-425B-4FED-B056-3A43613B072F} /v Backups /d "True"