# UNINSTALL
$appToRemove = "commvault"
[array]$cachedInstallers = Get-ChildItem "C:\ProgramData\Package Cache" -Recurse -Exclude *.msi | 
    Where-Object { $_.Name -match $appToRemove -or $_.VersionInfo.CompanyName -match $appToRemove } |
    Select-Object -ExpandProperty FullName
foreach( $exe in $cachedInstallers ){
    start-process $exe -ArgumentList "/silent /uninstall" -wait
}