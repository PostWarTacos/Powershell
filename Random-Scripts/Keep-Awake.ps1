# Prevent idle without affecting mouse or keyboard
Add-Type -AssemblyName System.Windows.Forms

while ($true) {
    # Simulate "last input" reset every 4 minutes
    [System.Windows.Forms.Application]::DoEvents()
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Windows.Forms.SendKeys]::SendWait("{F15}")
    Start-Sleep -Seconds 240
}
