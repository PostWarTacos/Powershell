<#
#####################################################################################
Name    :   RemoveAnyConnect.ps1
Purpose :   Removes registry keys that are left behind after AnyConnect failed to update
Created :   11/8/2018
Author  :   Matthew T Wurtz
Company :   189th Communications Flight / AR Air National Guard
#####################################################################################
#>

#Get-ChildItem -path HKLM:\ -Recurse | where {$_.Name -match 'AnyConnect'} <# | Remove-Item -Force #>

$Computer = "NKAGW-112626"
$Hive = 'LocalMachine'
$KeyPath = 'Software\Classes'
$Value = 'Cisco AnyConnect Secure Mobility Client VPN COM API'
$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("$hive", "$Computer")
$key = $reg.OpenSubKey("$KeyPath")
$SDC = $key.GetValue($Value)
$KeyPath
$Computer