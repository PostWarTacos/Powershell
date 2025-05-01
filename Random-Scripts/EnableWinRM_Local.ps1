# Enable PSRemoting
Enable-PSRemoting -Force

# Configure WinRM for HTTP
winrm quickconfig

# Set firewall rules to allow WinRM traffic
Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC" -Enabled True
Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP" -Enabled True

# Enable CredSSP authentication
Enable-WSManCredSSP -Role Client

# Output status
Write-Host "WinRM has been enabled on the local machine."
