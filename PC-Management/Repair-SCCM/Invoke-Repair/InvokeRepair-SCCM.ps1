<#
#
#   Intent: Copies InvokeRepair-SCCM.ps1 to local system for better manageability of script.
#    InvokeRepair-SCCM is intended to be a testbed for Repair-SCCM. Making it easier to develop the script and ensure it works properly.
#   Date: 10-Mar-25
#   Author: Matthew Wurtz
#
#>

$session = New-PSSession -ComputerName 

$filePath = "C:\users\wurtzmt\documents\coding\powershell\pc-management\repair-sccm\invoke-repair\InvokeRepair-SCCM.ps1"

# Execute it remotely
Invoke-Command -Session $session -FilePath $filePath

# Clean up session
Remove-PSSession *
