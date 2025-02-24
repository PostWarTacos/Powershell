<#
#####################################################################################
Name    :   RunningProcesses.ps1
Purpose :   Show list of running processes on a remote computer and choose which
            processes to kill
Created :   11/7/2018
Author  :   Matthew T Wurtz
Company :   189th Communications Flight / AR Air National Guard
#####################################################################################
#>

Clear-Host

Function Start_Index
    {

    }
Function Stop_Index
    {
    "What process would you like to stop?"
    #
    # Another list of common programs to kill
    #
    #
    }
Function List_Index
    {
    get-process -ComputerName $Computer | Select ProcessName, ID
    }
Function Computer_Index
    {
    $Computer=Read-Host "Enter computer name:"
    }

$Computer=Read-Host "Enter computer name:"

Do
    {
	$Caption = "What action would you like to take?";
	$Message = "";
	$Start = New-Object System.Management.Automation.Host.ChoiceDescription "&Start Service","Start";
	$Stop = New-Object System.Management.Automation.Host.ChoiceDescription "&Stop Service","Stop";
	$List = New-Object System.Management.Automation.Host.ChoiceDescription "&List Services","List";
    $Computername = New-Object System.Management.Automation.Host.ChoiceDescription "&Computername","Computername";
    $Exit = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit","Exit";
	$Choices = [System.Management.Automation.Host.ChoiceDescription[]]($Start,$Stop,$List,$Computername,$Exit);
	$Answer = $host.ui.PromptForChoice($Caption,$Message,$Choices,0)
	Switch ($Answer)
		{
		0
			{
			Start_Index
			}
		1 
			{
			Stop_Index
			}
		2
			{
			List_Index
			}
		3
			{
			Computer_Index
			}
        4
			{
			$Complete = $True
			}
        }
    }until ($Complete -eq $true)