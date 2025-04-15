function Find-GUID{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$AppName
    )

    $appDirs = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    foreach ( $dir in $appDirs ){
        Get-ItemProperty $dir |
            Where-Object { $_.DisplayName -match $AppName -or $_.Publisher -match $AppName } |
            Select-Object DisplayName, Publisher, DisplayVersion, PSChildName, UninstallString, @{ Name='Path'; Expression={ $_.PSPath -replace '^Microsoft\.PowerShell\.Core\\Registry::', '' }} |
            Format-List
    }
}

Export-ModuleMember Find-GUID