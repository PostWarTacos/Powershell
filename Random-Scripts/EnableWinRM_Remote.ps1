# Define the remote computer name or IP address
$remoteComputer = "RemoteMachineName"

# Define the credentials for the remote machine
$credential = Get-Credential

# Enable WinRM using CIM
Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine = "powershell -NoProfile -Command Enable-PSRemoting -Force"} -ComputerName $remoteComputer -Credential $credential

# Output status
Write-Host "WinRM has been enabled on the remote machine $remoteComputer."
