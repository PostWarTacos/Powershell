<#
#####################################################################################
Name    :   ComputerList.ps1
Purpose :   Pings list of computers and pulls all details from it. Exports details
            to a CSV file
Created :   10/3/2018
Author  :   Matthew T Wurtz
Company :   189th Communications Flight / AR Air National Guard
#####################################################################################
#>
 
$exportLocation = 'C:\scripts\ComputerList\pcInventory.csv'
Set-Variable -Name "InitialHostsDirectory" -Value "C:\users\1365935510N\Desktop"
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
 
# Test connection to each computer before getting the inventory info
Clear-Host
foreach ($computer in $testcomputers) {
Write-host ("Checking Network Connection to:" + $computer) -ForegroundColor Cyan
  if (Test-Connection -ComputerName $computer -Quiet -count 2){
    Add-Content -value $computer -path c:\scripts\ComputerList\livePCs.txt
  }else{
    Add-Content -value $computer -path c:\scripts\ComputerList\deadPCs.txt
  }
}
 
 
# Now that we know which PCs are live on the network
# proceed with the inventory
 
$computers = Get-Content -Path 'C:\scripts\ComputerList\livePCs.txt'
 
foreach ($computer in $computers) {
Write-host ("Checking Inventory for: "+$computer)
    $Bios = Get-WmiObject win32_bios -Computername $Computer
    $Hardware = Get-WmiObject Win32_computerSystem -Computername $Computer
    $Sysbuild = Get-WmiObject Win32_WmiSetting -Computername $Computer
    $OS = Get-WmiObject Win32_OperatingSystem -Computername $Computer
    $Networks = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer | Where-Object {$_.IPEnabled}
    $driveSpace = Get-WmiObject win32_volume -computername $Computer -Filter 'drivetype = 3' | 
    Select-Object PScomputerName, driveletter, label, @{LABEL='GBfreespace';EXPRESSION={'{0:N2}' -f($_.freespace/1GB)} } |
    Where-Object { $_.driveletter -match 'C:' }
    $cpu = Get-WmiObject Win32_Processor  -computername $computer
    $EDIPINumber = Get-ChildItem "\\$computer\c$\Users" | 
        ?{$_.PSIsContainer -and $_.FullName -like "*\users\*" -and  $_.FullName -notlike "*\Users\USAF_Admin*" -and  $_.FullName -notlike "*\Users\Public*" -and  $_.FullName -notlike "*\Users\ADMIN*" -and  $_.FullName -notlike "*\Users\Default*"} |
        Sort-Object LastWriteTime -Descending | Select-Object Name, LastWriteTime, Fullname -first 1
    If ($EDIPINumber.FullName -eq $null) {
        $UserName = Get-ChildItem "\\$computer\c$\Users" | Sort-Object LastWriteTime -Descending | Select-Object Name, LastWriteTime, Fullname -first 1
    } Else {
        $UserName = Get-aduser $EDIPINumber.Name
    }
    $totalMemory = [math]::round($Hardware.TotalPhysicalMemory/1024/1024/1024, 2)
    $lastBoot = $OS.ConvertToDateTime($OS.LastBootUpTime)

    #SDC Version
    $Hive = 'LocalMachine'
    $KeyPath = 'Software\Microsoft\Windows\CurrentVersion\OEMInformation'
    $Value = 'Model'
    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("$hive", "$computer")
    $key = $reg.OpenSubKey("$KeyPath")
    $SDC = $key.GetValue($Value)

    #AnyConnect
    $AnyConnect = (gwmi -Class win32_product -ComputerName $computer |
    Where Name -Like "*AnyConnect*" |
    select Name).Name

    If ($AnyConnect -Like "*AnyConnect*") {
        $AnyConnectResult = "true"
        $AnyConnectVersion = (gwmi -Class win32_product -ComputerName $computer |
        Where Name -Like "*AnyConnect*" |
        select Version).Version
    } Else {
        $AnyConnectResult = "false"
    }

    #Connection Monitor
    $ConMon = (gwmi -Class win32_product -ComputerName $computer |
    Where Name -Like "*Monitor*" |
    select Name).Name
        
    If ($ConMon -Like "*Monitor*") {
        $ConMonResult = "true"
        $ConMonVersion = (gwmi -Class win32_product -ComputerName $computer |
        Where Name -Like "*Monitor*" |
        select Version).Version
    } Else {
        $ConMonResult = "false"
    }

 
    $IPAddress  = $Networks.IpAddress[0]
    $MACAddress  = $Networks.MACAddress
    $systemBios = $Bios.serialnumber
 
    $OutputObj  = New-Object -Type PSObject
    $OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.ToUpper()
    $OutputObj | Add-Member -MemberType NoteProperty -Name IP_Address -Value $IPAddress
    $OutputObj | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $Hardware.Manufacturer
    $OutputObj | Add-Member -MemberType NoteProperty -Name Model -Value $Hardware.Model
    $OutputObj | Add-Member -MemberType NoteProperty -Name System_Type -Value $Hardware.SystemType
    $OutputObj | Add-Member -MemberType NoteProperty -Name Operating_System -Value $OS.Caption
    $OutputObj | Add-Member -MemberType NoteProperty -Name SDC_Ver -Value $SDC
    $OutputObj | Add-Member -MemberType NoteProperty -Name OS_BuildVersion -Value $SysBuild.BuildVersion
    $OutputObj | Add-Member -MemberType NoteProperty -Name Serial_Number -Value $systemBios
    $OutputObj | Add-Member -MemberType NoteProperty -Name MAC_Address -Value $MACAddress
    $OutputObj | Add-Member -MemberType NoteProperty -Name EDIPI_Number -Value $EDIPINumber.Name
    $OutputObj | Add-Member -MemberType NoteProperty -Name User_Name -Value $UserName.Name
    $OutputObj | Add-Member -MemberType NoteProperty -Name Last_ReBoot -Value $lastboot
    $OutputObj | Add-Member -MemberType NoteProperty -Name AnyConnect -Value $AnyConnectResult
    $OutputObj | Add-Member -MemberType NoteProperty -Name AnyConnectVersion -Value $AnyConnectVersion
    $OutputObj | Add-Member -MemberType NoteProperty -Name ConMon -Value $ConMonResult
    $OutputObj | Add-Member -MemberType NoteProperty -Name ConMonVersion -Value $ConMonVersion
    $OutputObj | Export-Csv $exportLocation -Append
  }
Write-host ("Inventory Check Is Complete. Get Report at C:\Scripts\ComputerList\pcInventory.csv") -foregroundcolor Green