# Define the target application path
$TargetApp = "C:\Program Files\Notepad++\notepad++.exe"  # Change this to your desired application

# Create a shortcut in the Start Menu (if it doesn't already exist)
$ShortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\" + [System.IO.Path]::GetFileNameWithoutExtension($TargetApp) + ".lnk"

if (!(Test-Path $ShortcutPath)) {
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetApp
    $Shortcut.Save()
}

# Pin the shortcut to the taskbar
$Shell = New-Object -ComObject Shell.Application
$Folder = $Shell.Namespace((Get-Item $ShortcutPath).DirectoryName)
$Item = $Folder.ParseName((Get-Item $ShortcutPath).Name)

# Invoke the shell verb to pin the app
$Verb = $Item.Verbs() | Where-Object { $_.Name -match "Pin to start" }

if ($Verb) {
    $Verb.DoIt()
    Write-Output "Successfully pinned to taskbar."
} else {
    Write-Output "Pin to taskbar option not found. It may already be pinned."
}

get-process explorer | Stop-Process
Start-Process explorer