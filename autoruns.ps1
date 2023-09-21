<#
Using Powershell, find ALL autoruns. Remember that an autorun command can come from different locations
(ie: it can be in the registry, but not found in the startup folder).
#>

Get-CimInstance -ClassName Win32_StartupCommand |
  Select-Object -Property Command, Description, User, Location |
  Out-GridView