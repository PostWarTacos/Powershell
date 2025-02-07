clear-host
Import-Module 'C:\Program Files (x86)\WindowsPowerShell\modules\DRA'

Set-Variable -Name "InitialHostsDirectory" -Value "\\NKAGw-112626\C$\users\1365935510N\Desktop"
$HostFile = Get-FileName -initialDirectory "$InitialHostsDirectory"
$SecurityGroups = Get-Content -Path $HostFile

Function Get-FileName($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

$GroupsCount = ($SecurityGroups | measure-object).count
$i = 0

foreach ($Group in $SecurityGroups){
    Remove-NKAGGroup -GroupName $Group
    $i += 1
    $progress = (($i / $GroupsCount)*100).tostring("##.##")
    Write-Progress -Activity "Deleting Groups.." -Status $progress% -PercentComplete $progress
}

