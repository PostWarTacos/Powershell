<#
#####################################################################################
Name    :   UserLoggedOnComp.ps1
Purpose :   Query remote computer for list of users with active sessions
Created :   11/7/2018
Author  :   Matthew T Wurtz
Company :   189th Communications Flight / AR Air National Guard
#####################################################################################
#>

#Find logged in user of remote computer
clear-host
$computer=read-host "Enter computer name:"
$filepath= '\\' + $computer + '\C$\Users'

$U=gci $filepath | sort LastWriteTime | select -Last 1 | Select -expand Name
#$U=$U | Trim-Length 10

#Get-ADUser $U

$U

function Trim-Length {
param (
    [parameter(Mandatory=$True,ValueFromPipeline=$True)] [string] $Str
  , [parameter(Mandatory=$True,Position=1)] [int] $Length
)
    $Str[30..($Length-1)] -join ""
}