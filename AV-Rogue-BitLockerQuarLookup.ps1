<#
#####################################################################################
Name    :   AV-Rogue-BitlockerQuarLookup.ps1
Purpose :   Query ADUC to determine what computers are in AV, Rogue, or Bitlocker Quarantine
Created :   11/1/2018
Author  :   Matthew T Wurtz
Company :   189th Communications Flight / AR Air National Guard
#####################################################################################
#>
[System.Console]::BufferHeight = 10000
[System.Console]::WindowWidth = [System.Console]::LargestWindowWidth -25
[System.Console]::WindowHeight = [System.Console]::LargestWindowHeight -15
[System.Console]::Title = "Quarantine Lookup"
$Initial_Directory = $Env:UserProfile + "\Desktop\"
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
If (!$ScriptPath){$ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path}
$VSE_Group = "*GLS_299 NOSS_Quarantine AV Computers*"
$Rogue_Group = "*GLS_299 NOSS_Rogue Systems Quarantine*"
$BitLocker_Group = "*GLS_299 NOSS_BITLOCKER QUARANTINE*"
$OU_To_Search = ([ADSISearcher]"(&(sAMAccountName=$env:COMPUTERNAME$))").FindOne().Properties['distinguishedName'][0].replace(("CN=" + $Env:Computername + ",OU=Little Rock ANG Computers,"),"")
Function VSE_Index
	{
	$Filter = "LDAP://$OU_To_Search"
	$Searcher = [adsisearcher]'(&(objectCategory=computer))'
	$Searcher.Searchroot = [adsi]$Filter
	$Searcher.PageSize = 10000
	$List_In_VSE_Quar = $Searcher.FindAll().Properties | Where {$_.memberof -Like $VSE_Group} | Foreach {$_.name} | Sort-Object
	Write-host ""
	Write-host ""
	If($List_In_VSE_Quar.count -gt 30)
		{
		Write-host -NoNewLine "There are currently: ";Write-Host -NoNewLine "$($List_In_VSE_Quar.count)" -ForegroundColor Red;Write-Host " Systems In VSE Quarantine"
		Write-host ""
		Read-host "Press Enter To Contine"
		}
	Write-host ""
	Write-host "Each system Found has a VSE DAT file that is more than 7 days old" -ForegroundColor Yellow
	Write-host ""
	Write-host -NoNewLine "Number of systems in VSE Quarantine: ";Write-host "$($List_In_VSE_Quar.count)" -Foregroundcolor yellow;`
	Write-host "----------------------------------------";`
	Foreach($sys in $List_In_VSE_Quar){Write-host $Sys}
	Write-host ""
	$Caption = "`n`nWhat action would you like to take?`n";
	$Message = "";
	$Clip = New-Object System.Management.Automation.Host.ChoiceDescription "&Copy To Clipboard","Clipboard";
	$Exit = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit","Exit";
	$Choices = [System.Management.Automation.Host.ChoiceDescription[]]($Clip,$Exit);
	$Answer = $host.ui.PromptForChoice($Caption,$Message,$Choices,0)
	Switch ($Answer)
		{
		0
			{
			$List_In_VSE_Quar | Clip.exe
			}
		1 
			{
			# Exit
			}
		}
	}
Function BitLocker_Index
	{
	$Filter = "LDAP://$OU_To_Search"
	$Searcher = [adsisearcher]'(&(objectCategory=computer))'
	$Searcher.Searchroot = [adsi]$Filter
	$Searcher.PageSize = 10000
	$List_In_BitLocker_Quar = $Searcher.FindAll().Properties | Where {$_.memberof -Like $BitLocker_Group} | Foreach {$_.name} | Sort-Object
	Write-host ""
	Write-host ""
	If($List_In_BitLocker_Quar.count -gt 30)
		{
		Write-host -NoNewLine "There are currently: ";Write-Host -NoNewLine "$($List_In_BitLocker_Quar.count)" -ForegroundColor Red;Write-Host " Systems In BitLocker Quarantine"
		Write-host ""
		Read-host "Press Enter To Contine"
		}
	Write-host ""
	Write-host -NoNewLine "Number of systems in BitLocker Quarantine: ";Write-host "$($List_In_BitLocker_Quar.count)" -Foregroundcolor yellow;`
	Write-host "----------------------------------------";`
	Foreach($sys in $List_In_BitLocker_Quar){Write-host $Sys}
	Write-host ""
	$Caption = "`n`nWhat action would you like to take?`n";
	$Message = "";
	$Clip = New-Object System.Management.Automation.Host.ChoiceDescription "&Copy To Clipboard","Clipboard";
	$Exit = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit","Exit";
	$Choices = [System.Management.Automation.Host.ChoiceDescription[]]($Clip,$Exit);
	$Answer = $host.ui.PromptForChoice($Caption,$Message,$Choices,0)
	Switch ($Answer)
		{
		0
			{
			$List_In_BitLocker_Quar | Clip.exe
			}
		1 
			{
			# Exit
			}
		}
	}
Function Rogue_Index
	{
	$Filter = "LDAP://$OU_To_Search"
	$Searcher = [adsisearcher]'(&(objectCategory=computer))'
	$Searcher.Searchroot = [adsi]$Filter
	$Searcher.PageSize = 10000
	$List_In_Rogue_Quar = $Searcher.FindAll().Properties | Where {$_.memberof -Like $Rogue_Group} | Foreach {$_.name} | Sort-Object
	Write-host ""
	Write-host ""
	If($List_In_Rogue_Quar.count -gt 50)
		{
		Write-host -NoNewLine "There are currently: ";Write-Host -NoNewLine "$($List_In_Rogue_Quar.count)" -ForegroundColor Red;Write-Host " Systems In Rogue Quarantine"
		Write-host ""
		Read-host "Press Enter To Contine"
		}
	Write-host "Review your domain removal process and delete dead objects" -ForegroundColor Yellow
	Write-host "Ensure that the McAfee Agent is installed on all systems" -ForegroundColor Yellow
	Write-host ""
	Write-host -NoNewLine "Number of systems in Rogue Quarantine: ";Write-host "$($List_In_Rogue_Quar.count)" -Foregroundcolor yellow;`
	Write-host "----------------------------------------";`
	Foreach($sys in $List_In_Rogue_Quar){Write-host $Sys}
	Write-host ""
		$Caption = "`n`nWhat action would you like to take?`n";
	$Message = "";
	$Clip = New-Object System.Management.Automation.Host.ChoiceDescription "&Copy To Clipboard","Clipboard";
	$Exit = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit","Exit";
	$Choices = [System.Management.Automation.Host.ChoiceDescription[]]($Clip,$Exit);
	$Answer = $host.ui.PromptForChoice($Caption,$Message,$Choices,0)
	Switch ($Answer)
		{
		0
			{
			$List_In_Rogue_Quar | Clip.exe
			}
		1 
			{
			# Exit
			}
		}
	}

cls
$Caption = "OU Path From System is: $OU_To_Search";
$Message = "Is this OU Path Correct?";
$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Use Automatic";
$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No -Manually Input","Manually Input";
$Choices = [System.Management.Automation.Host.ChoiceDescription[]]($Yes,$No);
$Answer = $host.ui.PromptForChoice($Caption,$Message,$Choices,0)
Switch ($Answer)
	{
	0
		{
		# Do Nothing and Continue
		}
	1 
		{
		$OU_To_Search = Read-Host -Prompt "Enter OU Path:"
		}
	}
try
	{
	If([ADSI]::Exists("LDAP://$OU_To_Search"))
		{
		Cls
		Write-host "LDAP Entry is Valid: $OU_To_Search" -ForegroundColor Green
		}
	else
		{
		cls
		Write-host "LDAP Entry is NOT Valid: $OU_To_Search" -ForegroundColor Red
		}
	}
catch
	{
	Write-host "Error Occured while Querying the OU that was Entered" -ForegroundColor Red
	Read-Host "Press Enter to Exit..."
	Exit
	}

Do
	{
	$Caption = "`n`nWhat action would you like to take?`n";
	$Message = "";
	$VSE = New-Object System.Management.Automation.Host.ChoiceDescription "&VSE Check","VSE";
	$Rogue = New-Object System.Management.Automation.Host.ChoiceDescription "&Rogue Check","Rogue";
	$BitLocker = New-Object System.Management.Automation.Host.ChoiceDescription "&BitLocker Check","BitLocker";	
	$Exit = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit","Exit";
	$Choices = [System.Management.Automation.Host.ChoiceDescription[]]($VSE,$Rogue,$BitLocker,$Exit);
	$Answer = $host.ui.PromptForChoice($Caption,$Message,$Choices,0)
	Switch ($Answer)
		{
		0
			{
			VSE_Index
			}
		1 
			{
			Rogue_Index
			}
		2
			{
			BitLocker_Index
			}
        3
			{
			$Complete = $True
			}
		}
	}Until($Complete -eq $True)