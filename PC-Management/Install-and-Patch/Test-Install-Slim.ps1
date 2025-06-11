# UNINSTALL
$appToRemove = "commvault"
[array]$cachedInstallers = Get-ChildItem "C:\ProgramData\Package Cache" -Recurse -Exclude *.msi |
    Where-Object { $_.Name -match $appToRemove -or $_.VersionInfo.CompanyName -match $appToRemove } |
    Select-Object -ExpandProperty FullName

foreach ( $exe in $cachedInstallers ) {
    Start-Process $exe -ArgumentList "/silent /uninstall" -Wait -Verbose
}

# INSTALL
$appToInstall = ".\WindowsEndpoint64_Permanent.exe"
$proc = Start-Process $appToInstall -ArgumentList "/silent /install" -PassThru -Verbose
$proc.WaitForExit()

# FIND keyPath
$root = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$keyPath = $null
$keys = Get-ChildItem -Path $root -ErrorAction SilentlyContinue

foreach ( $key in $keys ) {
    $keyChildName = Get-ItemProperty $key.pspath -ErrorAction SilentlyContinue | 
        Where-Object { $_.DisplayName -match $appToRemove -or $_.Publisher -match $appToRemove } |
        Select-Object -ExpandProperty PSPath

    $keyPath = $root + "\" + $keyChildName
}

# MODIFY REGISTRY
# $keyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EB6937E8-425B-4FED-B056-3A43613B072F}"
$regName = "Backups"
$regValue = "True"
$timeout = 180
$elapsed = 0

while ( -not ( Test-Path $keyPath ) -and ( $elapsed -lt $timeout )) {
    Start-Sleep -Seconds 5
    $elapsed += 5
}

Set-ItemProperty -Path $keyPath -Name $regName -Value $regValue -Force -Verbose