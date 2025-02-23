<#
#####################################################################################
Name    :   CmpNoLogon.ps1
Purpose :   Finds computers in ADUC that have not contacted the domain controller in X number of days.
Created :   5/16/2019
Author  :   Matthew T Wurtz
#####################################################################################
#>

$Comp_OU = "[YOUR BASES COMPUTER OU]"
$Cmp_LogonReq = (Get-Date).Adddays(-(90))
$MyComputer = '[YOUR COMPUTERNAME]'
$exportLocation = "\\$MyComputer\c$\Scripts\AD-Reports\ComputersNoContactWithDC.csv"

$AllComputers = Get-ADComputer -SearchBase $Comp_OU -Filter *

If ((Test-Path \\$MyComputer\C$\Scripts) -eq $false){
    New-Item -ItemType Directory -Path \\$MyComputer\C$\ -Name Scripts
}

If ((Test-Path \\$MyComputer\C$\Scripts\AD-Reports) -eq $false){
    New-Item -ItemType Directory -Path \\$MyComputer\C$\Scripts -Name AD-Reports
}

Foreach($Computer in $AllComputers) {
    $CompName = $Computer.Name
    $Comp_Enabled = $Computer.Enabled
    $Cmp_LastLogon = [datetime]::FromFileTime((Get-ADComputer -Identity $Computer -Properties LastLogonTimeStamp).LastLogonTimeStamp)
    if($Cmp_LastLogon -lt $Cmp_LogonReq){
        $OutputObj  = New-Object -Type PSObject
        $OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $CompName
        $OutputObj | Add-Member -MemberType NoteProperty -Name LastLogon -Value $Cmp_LastLogon
        $OutputObj | Export-Csv $exportLocation -Append
    }
}
