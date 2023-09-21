<#
Write a script that will provide a list of users that haven't logged on in X number of days.
#>

$Days = Read-Host "How many days will dictate a stale account?"

Get-childItem -Path ("C:\Users") | ? {$_.Name -notlike "*USAF_Admin*" -and  $_.Name -notlike "*Public*" -and  $_.Name -notlike "*ADMIN*" -and  $_.Name -notlike "*Default*"} | `
select  Name,LastWriteTime | Where {$_.LastWriteTime -lt $(Get-Date).AddDays(-$Days)}
