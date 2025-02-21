<# Broken SCCM
CARBO071
CVOLU006

CMCCA037
CMCCA042
CMCCA066
CMCCA012
CMCCA056
CMCCA072
CMCCA028
CPRES026
CLATH041
#>

<# Valid SCCM
CLABB024
#>

#$Computers = @("CARBO071", "CVOLU006", "CLABB024") # initial test group
# WMIC Testing Group
$Computers = Get-Content $env:USERPROFILE\Desktop\testingWMIC.txt
$Sessions = New-PSSession -ComputerName $Computers

# WMIC test
Invoke-Command -Session $Sessions -ScriptBlock {
    write-output `n
    hostname
    ipconfig | findstr /i ipv4
    #wmic /NAMESPACE:\\root\ccm path sms_client
    #wmic /NAMESPACE:\\root\CCM path SMS_Client call GetAssignedSite
    wmic /NAMESPACE:\\root\ccm path sms_authority | ForEach-Object { ($_ -split '\s{2,}')[1] }  # possible issue
    #wmic /NAMESPACE:\\root\ccm\locationservices path SMS_MPInformation
    #wmic /NAMESPACE:\\root\CCM\SoftwareUpdates\WUAHandler path CCM_UpdateSource
    #wmic /NAMESPACE:\\root\CCM\Clientsdk path CCM_ClientUtilities call determineifrebootpending
    #wmic /NAMESPACE:\\root\CCM\SoftwareUpdates\UpdatesStore path CCM_UpdateStatus get Article,Bulletin,Title,ScanTime,Status
    #wmic /NAMESPACE:\\root\ccm\policy\machine\actualconfig path ccm_rebootsettings
    write-output `n
}


<# Proxy Check
Invoke-Command -Session $Sessions -ScriptBlock {
    netsh winhttp show proxy
}
#>

<# WU Server
Invoke-Command -Session $Sessions -ScriptBlock {
param ($Path, $Key)
if (Test-Path $Path) {
Get-ItemProperty -Path $Path -Name $Key | Select-Object PSComputerName, $Key
} else {
Write-Output "$env:COMPUTERNAME - Registry path not found"
}
} -ArgumentList "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate", "WUStatusServer"
#>

Remove-PSSession *  # Clean up sessions after use