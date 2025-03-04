<#
#####################################################################################
Name    :   ForceUserLogoff.ps1
Purpose :   Forces user logoff on remote computer
Created :   5/16/2019
Author  :   Matthew T Wurtz
#####################################################################################
#>

Clear-Host
Import-Module ActiveDirectory
$Users_OU = "[YOUR USERS OU]"


$ComputerName = Read-host "Enter computername"

# Find all sessions on remote computer
$Sessions =  Invoke-Command -ComputerName $ComputerName -ScriptBlock { quser }
$SessionIDs = $Sessions | Select -skip 1

# Parse the session IDs from the output
$SessionIDsCount = ($SessionIDs | measure-object).count
Write-Host
Write-Host "Found $SessionIDsCount user login(s) onto $ComputerName."
Write-Host

$i = 0

# Loop through each session ID and pass each to the logoff command
Foreach ($Session in $SessionIDs) {
    $EDIPI = ($Session -split ' +')[1]
    $UniqueSessionID = ($Session -split ' +')[2]
    $User = Get-ADUser -SearchBase $Users_OU -Filter "gigID -eq '$EDIPI'"
    $i += 1
    if($Session -like '*console*'){
        write-host "SessionID: $i    " -ForegroundColor Red -NoNewline; Write-host "Username:" $User.name -NoNewline; write-host "     THIS IS THE ACTIVE USER." -ForegroundColor yellow;
    }
    Else{
         write-host "SessionID: $i    " -ForegroundColor Red -NoNewline; Write-host "Username:" $User.name
    }
}

Write-Host
$Selection = Read-Host "Enter session ID you want to logoff"
Write-Host

$LogoffSession = $SessionIDs | Select-Object -Last (($SessionIDs | Measure-Object ).Count - ($Selection-1)) | Select-Object -First 1
$LogoffSessionID = ($LogoffSession -split ' +')[2]
$LogoffSessionID


#logoff $LogoffSessionID /server:$Computername
