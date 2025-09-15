<#
#####################################################################################
Name    :   InactiveUsersAndComputers.ps1
Purpose :   Query ADUC to determine what users haven't logged on in X number of days
            and what computers haven't contacted the DC in X number of days
Created :   9/29/2021
Author  :   Matthew T Wurtz
#####################################################################################
#>

Clear-host
import-module activedirectory  

$inactivecomp = "C:\scripts\ad-reports\inactivecomputers_" + (Get-Date -format MM/dd/yy) + ".csv"
$inactiveuser = "C:\scripts\ad-reports\inactiveusers_" + (Get-Date -format MM/dd/yy) + ".csv"
$SearchBase = "" # <PUT YOUR FULL OU PATH HERE, BETWEEN THE DOUBLE QUOTES> #
If ((Test-Path C:\Scripts) -eq $false)
{
New-Item -ItemType Directory -Path C:\ -Name Scripts
}

If ((Test-Path C:\Scripts\AD-Reports) -eq $false)
{
New-Item -ItemType Directory -Path C:\scripts -Name AD-Reports
}

Function CompCheck_Index
    {
        Write-Host ""
        $DaysInactive = Read-host "Define how many days equals inactive"
        $time = (Get-Date).Adddays(-($DaysInactive))
# Get inactive computer report
        Get-ADComputer -SearchBase $SearchBase -Filter {LastLogonTimeStamp -lt $time} -Properties LastLogonTimeStamp |
        select-object Name,@{Name="LastSeen"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}} | 
        sort -Property LastSeen |
        export-csv $inactivecomp -notypeinformation -Force
# Completed Message
        Write-Host "Inactive Computers Report Completed. It can be found at C:\Scripts\AD-Reports" -ForegroundColor Red
        Pause
    }

Function UserCheck_Index
    {
        Write-Host ""
        $DaysInactive = Read-host "Define how many days equals inactive"
        $time = (Get-Date).Adddays(-($DaysInactive))
# Get inactive user report
        Get-ADUser -SearchBase $SearchBase -Filter {LastLogonDate -lt $time} -Properties LastLogonDate |
        Select Name, Enabled, LastLogonDate |
        Sort LastLogonDate |
        Export-Csv -Path $inactiveuser -NoTypeInformation -Force
# Completed Message
        Write-Host "Inactive Computers Report Completed. It can be found at C:\Scripts\AD-Reports" -ForegroundColor Red
        Pause
    }

Function Delete_Comp
    {
        Write-Host ""
        $CompTargets = (Import-Csv $inactivecomp).name
# Delete each computer in target list
        Foreach ($targ in $CompTargets){
            Remove-ADComputer $targ
        }
# Completed Message
        Write-Host "Deleting Inactive Computers Completed." -ForegroundColor Red
        Pause
    }

Function Delete_User
    {
        Write-Host ""
        $UserTargets = (Import-Csv $inactiveuser).name
# Delete each user in target list
        Foreach ($targ in $UserTargets){
            Remove-ADUser $targ
        }        
# Completed Message
        Write-Host "Deleting Inactive Users Completed." -ForegroundColor Red
        Pause
    }

Do
	{
    Clear-Host
	$Caption = "Inactive Users and Computers Reporting Tool";
	$Message = "`n`nWhat action would you like to take?`n";
	$CompCheck = New-Object System.Management.Automation.Host.ChoiceDescription "Inactive Computer Check";
	$UserCheck = New-Object System.Management.Automation.Host.ChoiceDescription "Inactive User Check";
	$CompDelete = New-Object System.Management.Automation.Host.ChoiceDescription "Inactive Computer Delete";
	$UserDelete = New-Object System.Management.Automation.Host.ChoiceDescription "Inactive User Delete";
	$Exit = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit";
	$Choices = [System.Management.Automation.Host.ChoiceDescription[]]($CompCheck,$UserCheck,$CompDelete,$UserDelete,$Exit);
	$Answer = $host.ui.PromptForChoice($Caption,$Message,$Choices,-1)
	Switch ($Answer)
		{
		0
			{
			CompCheck_Index
			}
		1 
			{
			UserCheck_Index
			}
        2
			{
			Delete_Comp
			}
		3 
			{
			Delete_User
			}
		4
			{
			$Complete = $True
			}
		}
	}Until($Complete -eq $True)
