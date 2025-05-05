$creds = Get-Credential -Credential dds.dillards.net\wurtzmt

Start-Process "cmd.exe" -Credential $creds -ArgumentList "/c exit" -NoNewWindow -Wait

exit