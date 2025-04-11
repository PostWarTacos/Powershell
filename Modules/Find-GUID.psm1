function Find-GUID{
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]$AppName
    )
    Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Where-Object DisplayName -match $AppName | Select-Object DisplayName, PSChildName, DisplayVersion
    
}