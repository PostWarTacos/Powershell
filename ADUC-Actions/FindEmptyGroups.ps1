<#
#####################################################################################
Name    :   FindEmptyGroups.ps1
Purpose :   Query ADUC to determine what security groups are empty
Created :   7/16/2019
Author  :   Matthew T Wurtz
#####################################################################################
#>

Clear-host
import-module activedirectory 

#Enter your computername here for script results to be exported to your computer
$MyComputer = '[YOUR COMPUTERNAME]'

If ((Test-Path \\$MyComputer\C$\Scripts) -eq $false)
{
New-Item -ItemType Directory -Path \\$MyComputer\C$\ -Name Scripts
}

If ((Test-Path \\$MyComputer\C$\Scripts\AD-Reports) -eq $false)
{
New-Item -ItemType Directory -Path \\$MyComputer\C$\scripts -Name AD-Reports
}


#Get all security group names automatically
$Groups = Get-ADGroup -SearchBase "[YOUR BASES GROUPS OU]" -Filter * | Select-Object -ExpandProperty Name

#Count number of users in each security group
foreach($Group in $Groups){
    Try{
        $UserCount = (Get-ADGroupMember $Group).count
        if($UserCount -eq 0){
            $Group >> \\$MyComputer\C$\Scripts\AD-Reports\EmptyGroups.csv
        }
    }

    Catch{
        $Group >> \\$MyComputer\C$\Scripts\AD-Reports\IssuesReading_EmptyGroups.csv
    }
}
