Function Get-FileName() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$InitialDirectory
    )
    
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $InitialDirectory
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename

}

$scriptPath = Get-FileName -InitialDirectory C:\Users\wurtzmt\Documents\Coding # Path to your script
$bytes = [System.Text.Encoding]::Unicode.GetBytes((Get-Content $scriptPath -Raw))
$encodedCommand = [Convert]::ToBase64String($bytes)

Write-Output $encodedCommand
Write-Output $encodedCommand | Set-Clipboard  # Copies to clipboard
Write-Host "Encoded Command has been copied to clipboard" -ForegroundColor Yellow