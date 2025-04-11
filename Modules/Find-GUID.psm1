function Find-GUID{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$AppName
    )
    Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Where-Object DisplayName -match $AppName | Select-Object DisplayName, PSChildName, DisplayVersion
    
}

Export-ModuleMember Find-GUID