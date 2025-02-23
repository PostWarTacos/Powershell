Function Get-FileName($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}


$Computer = Read-host Hostname
$File = '\\189aw-fs-02\GLOBAL\NCC\TCNOs\_test\VLC'

Copy-Item -Path $File -Destination "\\$Computer\C$\Program Files (X86)\Temp" -Recurse -Force

$Patch = Get-FileName "\\$Computer\C$\Program Files (x86)\temp"

$command = 'cmd.exe /c "' + $Patch + '" /Language=en_GB /S'
$process = [WMICLASS] "\\$Computer\ROOT\CIMV2:win32_process"
$process.Create($command)
