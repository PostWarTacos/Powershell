Set-Variable -Name "InitialHostsDirectory" -Value "\\NKAGW-112626\C`$\users\1365935510N\Desktop"
$HostFile = Get-FileName -initialDirectory "$InitialHostsDirectory"
$testcomputers = Get-Content -Path $HostFile
$Date = Get-Date -Format FileDate
$i = 0

# Select text file with computer names
Function Get-FileName($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

# Test if folders already exist
If ((Test-Path \\NKAGW-112626\C$\Scripts) -eq $false)
{
New-Item -ItemType Directory -Path \\NKAGW-112626\C$ -Name Scripts
}

If ((Test-Path \\NKAGW-112626\C$\Scripts\SoftwareScan) -eq $false)
{
New-Item -ItemType Directory -Path \\NKAGW-112626\C$\Scripts -Name SoftwareScan
}

# Delete Old Live/Old PCs File
    If ((Test-Path \\NKAGW-112626\C$\Scripts\SoftwareScan\LivePCs.txt) -eq $True)
    {
    Remove-Item -Path \\NKAGW-112626\C$\Scripts\SoftwareScan\LivePCs.txt -Force
    }
    If ((Test-Path \\NKAGW-112626\C$\Scripts\SoftwareScan\DeadPCs.txt) -eq $True)
    {
    Remove-Item -Path \\NKAGW-112626\C$\Scripts\SoftwareScan\DeadPCs.txt -Force
    }
    If ((Test-Path \\NKAGW-112626\C$\Scripts\SoftwareScan\$Date"SoftwareScan.csv") -eq $True)
    {
    Remove-Item -Path \\NKAGW-112626\C$\Scripts\SoftwareScan\$Date"SoftwareScan.csv" -Force
    }

# Test connection to each computer before getting the inventory info
Clear-Host
foreach ($Computer in $testcomputers) {
Write-host ("Checking Network Connection to:" + $computer) -ForegroundColor Cyan
  if (Test-Connection -ComputerName $computer -Quiet -count 2){
    Add-Content -value $Computer -path \\NKAGW-112626\C$\Scripts\SoftwareScan\livePCs.txt
  }else{
    Add-Content -value $Computer -path \\NKAGW-112626\C$\Scripts\SoftwareScan\deadPCs.txt
  }
}

# Reassign variable for $computers
$Computers = Get-Content -Path '\\NKAGW-112626\C$\Scripts\SoftwareScan\livePCs.txt'
$CompCount = ($Computers | measure-object).count

# Scan each computer for software installed
Foreach ($Computer in $Computers) {
    $Computer >> \\NKAGW-112626\C$\Scripts\SoftwareScan\$Date"SoftwareScan.csv"
    Get-CimInstance -ComputerName $Computer -ClassName win32_product -ErrorAction SilentlyContinue| Select-Object Name |
        where {$_.name -notlike "*ESD*" -and $_.name -notlike "*Microsoft Visual*" -and $_.name -notlike "*Microsoft Office*" -and $_.name -notlike "*Microsoft OneNote*" -and $_.name -notlike "*Microsoft Infopath*" -and $_.name -notlike "*Microsoft Excel*" `
        -and $_.name -notlike "*Microsoft Access*" -and $_.name -notlike "*Microsoft Outlook*" -and $_.name -notlike "*Microsoft Powerpoint*" -and $_.name -notlike "*Microsoft Publisher*" -and $_.name -notlike "*Microsoft Word*" `
        -and $_.name -notlike "*Google Chrome*" -and $_.name -notlike "*McAfee*" -and $_.name -notlike "*DSET*" -and $_.name -notlike "*Flash Player*" -and $_.name -notlike "*ActivClient*" -and $_.name -notlike "*Microsoft NetBanner*" `
        -and $_.name -notlike "*Adobe Acrobat*" -and $_.name -notlike "*Axway Desktop Validator*" -and $_.name -notlike "*Adobe Shockwave*"  -and $_.name -notlike "*Microsoft Skype*" -and $_.name -notlike "*Microsoft Groove*" `
        -and $_.name -notlike "*Microsoft Silverlight*" -and $_.name -notlike "*Microsoft Policy*" -and $_.name -notlike "*Google Update*" -and $_.name -notlike "*AFEMNS*" -and $_.name -notlike "*Microsoft DCF MUI*" `
        -and $_.name -notlike "*Configuration Manager Client*" -and $_.name -notlike "*ACCM*" -and $_.name -notlike "*   *"} >> \\NKAGW-112626\C$\Scripts\SoftwareScan\$Date"SoftwareScan.csv"

    # Progress bar
        $i += 1
        $progress = (($i / $CompCount)*100).tostring("##.##")
        Write-Progress -Activity "Scanning Computers.." -Status $progress% -PercentComplete $progress

}

# test 1
#Get-WmiObject -Class Win32_Product -ComputerName $ComputerName | Format-Wide -Column 1
