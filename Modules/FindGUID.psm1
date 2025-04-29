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

function Find-GUIDinMSI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$MSIPath
    )

    $installer = New-Object -ComObject WindowsInstaller.Installer
    $msi = $installer.OpenDatabase("$MSIPath", 0)
    $view = $msi.OpenView("SELECT * FROM Property")
    $view.Execute()
    while ($record = $view.Fetch()) {
        $name = $record.StringData(1)
        $value = $record.StringData(2)
        if ($name -in "ProductCode", "UpgradeCode", "ProductVersion") {
            Write-Host "$name = $value"
        }
    }
}

Export-ModuleMember Find-GUID, Find-GUIDinMSI