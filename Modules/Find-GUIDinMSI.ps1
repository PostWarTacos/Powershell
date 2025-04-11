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

Export-ModuleMember Find-GUIDinMSI