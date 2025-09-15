$user = "wurtzmt"

$fullUsername = "dds.dillards.net\$user"

Write-Host "Enter password for $fullUsername`:"

$Password = Read-Host -AsSecureString

$creds = New-Object System.Management.Automation.PSCredential ($fullUsername, $Password)

Start-Process "cmd.exe" -Credential $creds -ArgumentList "/c exit" -NoNewWindow -Wait

pause

exit