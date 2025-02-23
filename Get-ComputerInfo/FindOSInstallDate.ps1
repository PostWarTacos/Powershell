<#
#####################################################################################
Name    :   FindOSInstallDate.ps1
Purpose :   Finds OS install date and SDC version
Created :   11/7/2018
Author  :   Matthew T Wurtz
Company :   189th Communications Flight / AR Air National Guard
#####################################################################################
#>

$AdminComp = read-host "Enter computer name to export files to"

Clear-host

If ((Test-Path "\\$AdminComp\C$\Scripts") -eq $false)
{
New-Item -ItemType Directory -Path "\\$AdminComp\C$" -Name Scripts
}

If ((Test-Path "\\$AdminComp\C$\Scripts\OSInstall") -eq $false)
{
New-Item -ItemType Directory -Path "\\$AdminComp\C$\Scripts" -Name OSInstall
}

$exportLocation = "\\$AdminComp\C$\Scripts\OSInstall\OSInstall_List.csv"
Set-Variable -Name "InitialHostsDirectory" -Value %userprofile%
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

# Delete Old Report
        If ((Test-Path "\\$AdminComp\C$\Scripts\OSInstall\OSInstall_List.csv") -eq $True)
        {
            Write-Host ""
            $Caption = "Delete Old File";
            $Message = "Do you want to delete the old OS Install Report?";
            $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes";
            $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No";
            $Choices = [System.Management.Automation.Host.ChoiceDescription[]]($Yes,$No);
            $Answer = $host.ui.PromptForChoice($Caption,$Message,$Choices,-1)
            Switch ($Answer)
	            {
	            0
		            {
    		            Remove-Item -Path "\\$AdminComp\C$\Scripts\OSInstall\OSInstall_List.csv" -Force
                        If ((Test-Path "\\$AdminComp\C$\Scripts\OSInstall\livePCs.txt") -eq $True){
                            Remove-Item -Path "\\$AdminComp\C$\Scripts\OSInstall\livePCs.txt" -Force}
                        If ((Test-Path "\\$AdminComp\C$\Scripts\OSInstall\deadPCs.txt") -eq $True){
                            Remove-Item -Path "\\$AdminComp\C$\Scripts\OSInstall\deadPCs.txt" -Force}
		            }
	            1 
		            {
                        Write-host ""
		                Write-host "Before continuing, move old report to different location." -ForegroundColor Red
                        Write-host ""
                        Pause
		            }
	            }
        }


# Test connection to each computer before getting the inventory info
Clear-Host
foreach ($computer in $testcomputers) {
Write-host ("Checking Network Connection to:" + $computer) -ForegroundColor Cyan
  if (Test-Connection -ComputerName $computer -Quiet -count 2){
    Add-Content -value $computer -path "\\$AdminComp\C$\scripts\OSInstall\livePCs.txt"
  }else{
    Add-Content -value $computer -path "\\$AdminComp\C$\scripts\OSInstall\deadPCs.txt"
  }
}

$LivePCs = Get-Content -path "\\$AdminComp\C$\scripts\OSInstall\livePCs.txt"
$CompCount = ($LivePCs | measure-object).count
#$Computer=Read-host "Enter computer name"

foreach ($LivePC in $LivePCs){
    $i += 1
    $progress = (($i / $CompCount)*100).tostring("##.##")
    Write-Progress -Activity "Scanning $LivePC ($i of $CompCount)..."
    
    $InstallDate = ([WMI]'').ConvertToDateTime((Get-WmiObject Win32_OperatingSystem -ComputerName $LivePC).InstallDate)
    $Hive = 'LocalMachine'
    $KeyPath = 'Software\Microsoft\Windows\CurrentVersion\OEMInformation'
    $Value = 'Model'
    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("$hive", "$LivePC")
    $key = $reg.OpenSubKey("$KeyPath")
    $SDC = $key.GetValue($Value)
    $Sysbuild = Get-WmiObject Win32_WmiSetting -Computername $LivePC

    $OutputObj  = New-Object -Type PSObject
    $OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $LivePC
    $OutputObj | Add-Member -MemberType NoteProperty -Name SDC_Ver -Value $SDC
    $OutputObj | Add-Member -MemberType NoteProperty -Name OS_BuildVersion -Value $SysBuild.BuildVersion
    $OutputObj | Add-Member -MemberType NoteProperty -Name OS_InstallDate -Value $InstallDate
    $OutputObj | Export-Csv $exportLocation -Append
}
