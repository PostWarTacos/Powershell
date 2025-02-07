<#
#####################################################################################
Name    :   NetworkConnectionTest.ps1
Purpose :   Pings list of PCs and exports lists to two separate CSV files
Created :   11/7/2018
Author  :   Matthew T Wurtz
Company :   189th Communications Flight / AR Air National Guard
#####################################################################################
#>

Set-Variable -Name "InitialHostsDirectory" -Value "\\NKAGW-112GNG\c$\users\1365935510N\Desktop"
$HostFile = Get-FileName -initialDirectory "$InitialHostsDirectory"
$testcomputers = Get-Content -Path $HostFile

Function Get-FileName($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

#Count values in test computers for progress bar
$CompCount = ($testcomputers | measure-object).count
$i = 0
 
# Test connection to each computer before getting the inventory info
Clear-Host
foreach ($computer in $testcomputers) {
Write-host ("Checking Network Connection to:" + $computer) -ForegroundColor Cyan
  if (Test-Connection -ComputerName $computer -Quiet -count '1'){
    Add-Content -value $computer -path \\NKAGW-112GNG\c$\scripts\ComputerList\livePCs.txt
  }else{
    Add-Content -value $computer -path \\NKAGW-112GNG\c$\scripts\ComputerList\deadPCs.txt
  }
}