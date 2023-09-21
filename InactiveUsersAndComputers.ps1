<#
#####################################################################################
Name    :   InactiveUsersAndComputers.ps1
Purpose :   Query ADUC to determine what users haven't logged on in X number of days
            and what computers haven't contacted the DC in X number of days
Created :   11/7/2018
Author  :   Matthew T Wurtz
Company :   189th Communications Flight / AR Air National Guard
#####################################################################################
#>

Clear-host
import-module activedirectory  

$inactivecomp = 'C:\scripts\ad-reports\inactivecomputers.csv'
$inactiveuser = 'C:\scripts\ad-reports\inactiveusers.csv' 

If ((Test-Path C:\Scripts) -eq $false)
{
New-Item -ItemType Directory -Path C:\ -Name Scripts
}

If ((Test-Path C:\Scripts\AD-Reports) -eq $false)
{
New-Item -ItemType Directory -Path C:\scripts -Name AD-Reports
}

Function CompCheck_Index
    {
# Delete Old Report
        If ((Test-Path C:\Scripts\AD-Reports\inactivecomputers.csv) -eq $True)
        {
            Write-Host ""
            $Caption = "Delete Old File";
            $Message = "Do you want to delete the old Inactive Computers Report?";
            $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes";
            $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No";
            $Choices = [System.Management.Automation.Host.ChoiceDescription[]]($Yes,$No);
            $Answer = $host.ui.PromptForChoice($Caption,$Message,$Choices,-1)
            Switch ($Answer)
	            {
	            0
		            {
    		            Remove-Item -Path C:\Scripts\AD-Reports\inactivecomputers.csv -Force
		            }
	            1 
		            {
                        Write-host ""
		                Write-host "Before continuing, move old report to different location." -ForegroundColor Red
                        Write-host ""
                        Pause
		            }
	            }
        }
        Write-Host ""
        $DaysInactive = Read-host "Define how many days equals inactive"
        $time = (Get-Date).Adddays(-($DaysInactive))
# Get inactive computer report
        Get-ADComputer -SearchBase "OU=Little Rock ANG Computers,OU=Little Rock ANG,OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL" -Filter {LastLogonTimeStamp -lt $time} -Properties LastLogonTimeStamp |
        select-object Name,@{Name="LastSeen"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}} | 
        sort -Property LastSeen |
        export-csv $inactivecomp -notypeinformation -Force
# Completed Message
        Write-Host "Inactive Computers Report Completed. It can be found at C:\Scripts\AD-Reports" -ForegroundColor Red
        Pause
    }

Function UserCheck_Index
    {
# Delete Old Report
        If ((Test-Path C:\Scripts\AD-Reports\inactiveusers.csv) -eq $True)
        {
            Write-Host ""
            $Caption = "Delete Old File";
            $Message = "Do you want to delete the old Inactive Users Report?";
            $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes";
            $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No";
            $Choices = [System.Management.Automation.Host.ChoiceDescription[]]($Yes,$No);
            $Answer = $host.ui.PromptForChoice($Caption,$Message,$Choices,-1)
            Switch ($Answer)
	            {
	            0
		            {
    		            Remove-Item -Path C:\Scripts\AD-Reports\inactiveusers.csv -Force
		            }
	            1 
		            {
                        Write-host ""
		                Write-host "Before continuing, move old report to different location." -ForegroundColor Red
                        Pause
		            }
	            }
        }
        Write-Host ""
        $DaysInactive = Read-host "Define how many days equals inactive"
        $time = (Get-Date).Adddays(-($DaysInactive))
# Get inactive user report
        Get-ADUser -SearchBase "OU=Little Rock ANG Users,OU=Little Rock ANG,OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL" -Filter {LastLogonDate -lt $time} -Properties LastLogonDate |
        Select Name, Enabled, LastLogonDate |
        Sort LastLogonDate |
        Export-Csv -Path $inactiveuser -NoTypeInformation -Force
# Completed Message
        Write-Host "Inactive Computers Report Completed. It can be found at C:\Scripts\AD-Reports" -ForegroundColor Red
        Pause
    }

Do
	{
    Clear-Host
	$Caption = "Inactive Users and Computers Reporting Tool";
	$Message = "`n`nWhat action would you like to take?`n";
	$CompCheck = New-Object System.Management.Automation.Host.ChoiceDescription "Inactive &Computer Check";
	$UserCheck = New-Object System.Management.Automation.Host.ChoiceDescription "Inactive &User Check";
	$Exit = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit";
	$Choices = [System.Management.Automation.Host.ChoiceDescription[]]($CompCheck,$UserCheck,$Exit);
	$Answer = $host.ui.PromptForChoice($Caption,$Message,$Choices,-1)
	Switch ($Answer)
		{
		0
			{
			CompCheck_Index
			}
		1 
			{
			UserCheck_Index
			}
		2
			{
			$Complete = $True
			}
		}
	}Until($Complete -eq $True)
# SIG # Begin signature block
# MIIL7QYJKoZIhvcNAQcCoIIL3jCCC9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdA/Rd877xqMmiAGUgCMz8nA+
# fJiggglVMIIElDCCA3ygAwIBAgIDBPTVMA0GCSqGSIb3DQEBCwUAMFoxCzAJBgNV
# BAYTAlVTMRgwFgYDVQQKDA9VLlMuIEdvdmVybm1lbnQxDDAKBgNVBAsMA0RvRDEM
# MAoGA1UECwwDUEtJMRUwEwYDVQQDDAxET0QgSUQgQ0EtNDkwHhcNMTgxMTA1MDAw
# MDAwWhcNMjIxMTIzMTM0ODE1WjCBjTELMAkGA1UEBhMCVVMxGDAWBgNVBAoTD1Uu
# Uy4gR292ZXJubWVudDEMMAoGA1UECxMDRG9EMQwwCgYDVQQLEwNQS0kxDTALBgNV
# BAsTBFVTQUYxOTA3BgNVBAMTMENTLjE4OUNPTU1VTklDQVRJT05TRkxJR0hULVND
# T08tQ1lTUy0xOC0wMjdOLjAwMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAJq5ethS2Oobu/jfp9jHXrm+biQmfj9iisVi6QzaFJKoLSWhsQmR9ZIrATl9
# mdTs0KmV897S0GlQPIpEVon+/xkobW7yhCpLI37nK8RLDEfGcZ00jEgXo+S7x2aE
# 02rbvg8MxwmBs816E8mbr03vmzw058ycTu2anzVB9WYUICK39WhZpUi1p1UbTs5f
# RzOfUO7KS3PsZNEvU7wkHMk0eFsXLAjfB/R1xbcxhCLwHVFnmKrAd1a5OJ9MBBCI
# DpQ34Iaj9/ZEIn9yciEzXR5ZoZZmBy7e9v3OGw8ZptV+wWbmhL7EFGDDedhmMlMl
# ARTqBV8klPcHYxeoFrYQHTHSvusCAwEAAaOCAS0wggEpMB8GA1UdIwQYMBaAFNhn
# k8pG3MmVppSzBBicziU6lhxNMDcGA1UdHwQwMC4wLKAqoCiGJmh0dHA6Ly9jcmwu
# ZGlzYS5taWwvY3JsL0RPRElEQ0FfNDkuY3JsMA4GA1UdDwEB/wQEAwIHgDAWBgNV
# HSAEDzANMAsGCWCGSAFlAgELKjAdBgNVHQ4EFgQULkvRe2Lb53FIkku0oz1wkbpM
# CrgwZQYIKwYBBQUHAQEEWTBXMDMGCCsGAQUFBzAChidodHRwOi8vY3JsLmRpc2Eu
# bWlsL3NpZ24vRE9ESURDQV80OS5jZXIwIAYIKwYBBQUHMAGGFGh0dHA6Ly9vY3Nw
# LmRpc2EubWlsMB8GA1UdJQQYMBYGCisGAQQBgjcKAw0GCCsGAQUFBwMDMA0GCSqG
# SIb3DQEBCwUAA4IBAQCRXI/I4AkEh7rR49OpcKD278GIsgEIR54AiKcrE0ZIIOWF
# Cns5cdZWvp2Ovdqg1MYF9gsDVwhR/NeAPt9P9POu/FTvrCr/cSu+BCKYpuqNZIW9
# 94F+vqUk3HxzvNOcxHcXiZ96foOZu37KZhejp4Nc6gQBP6Wuo3XbMR3g7ro1AgzR
# QAQK6LrodLfe0Ggx0YDbOYf02AkfHubs4HR6MXeqJ7brzwvGYWylDwaQADrhZK6T
# IbdZ4nHL1L4tOIncVvQiV5ZCefQjMLpoiT3Oe3ECKquug5keeHWKg1821OLHtJld
# emm87OABqFwRCdCKxJ0rfmhaOqMt3ytoc9ERu7OfMIIEuTCCA6GgAwIBAgICAScw
# DQYJKoZIhvcNAQELBQAwWzELMAkGA1UEBhMCVVMxGDAWBgNVBAoTD1UuUy4gR292
# ZXJubWVudDEMMAoGA1UECxMDRG9EMQwwCgYDVQQLEwNQS0kxFjAUBgNVBAMTDURv
# RCBSb290IENBIDMwHhcNMTYxMTIyMTM0ODE1WhcNMjIxMTIzMTM0ODE1WjBaMQsw
# CQYDVQQGEwJVUzEYMBYGA1UECgwPVS5TLiBHb3Zlcm5tZW50MQwwCgYDVQQLDANE
# b0QxDDAKBgNVBAsMA1BLSTEVMBMGA1UEAwwMRE9EIElEIENBLTQ5MIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2EngKIwPCl9+dsIByO2uONNLKhpnFypB
# AE+LM8+kekt4/HG6StaU/fmqFTRiVI0Uh+td9BWe8NXOYrhQRo6FVSxBkLtWZX8P
# x2IHxiqQ1lnrZK9UlCo8h3MPpiN8VEjH2bP/WSa0oZEWzEDKLB5tSKerddc+QL2u
# EHb+Gfym6i+5qPOLXjV00FY24FdNOyHaRjQTM/LfsjWoFItHTKp5B9QogdKnyg+W
# kAARYtbd1nqtDXv6Fph5HaT39SEnRhc+lkrRDpDYc+HAU6Xywik+stgv2yFk1MhF
# pF5/rndEwMLIST0+lSpahJKGmYtg1VKcnDcq5CERC31gl6Yr7ffjAwIDAQABo4IB
# hjCCAYIwHwYDVR0jBBgwFoAUbIqUonexgHIdgXoWqvLczmbuRcAwHQYDVR0OBBYE
# FNhnk8pG3MmVppSzBBicziU6lhxNMA4GA1UdDwEB/wQEAwIBhjBnBgNVHSAEYDBe
# MAsGCWCGSAFlAgELJDALBglghkgBZQIBCycwCwYJYIZIAWUCAQsqMAsGCWCGSAFl
# AgELOzAMBgpghkgBZQMCAQMNMAwGCmCGSAFlAwIBAxEwDAYKYIZIAWUDAgEDJzAS
# BgNVHRMBAf8ECDAGAQH/AgEAMAwGA1UdJAQFMAOAAQAwNwYDVR0fBDAwLjAsoCqg
# KIYmaHR0cDovL2NybC5kaXNhLm1pbC9jcmwvRE9EUk9PVENBMy5jcmwwbAYIKwYB
# BQUHAQEEYDBeMDoGCCsGAQUFBzAChi5odHRwOi8vY3JsLmRpc2EubWlsL2lzc3Vl
# ZHRvL0RPRFJPT1RDQTNfSVQucDdjMCAGCCsGAQUFBzABhhRodHRwOi8vb2NzcC5k
# aXNhLm1pbDANBgkqhkiG9w0BAQsFAAOCAQEATmfPQPkolF5PB0fS/9DrngX0tmdS
# wlidBtrkY6vL/V7IMKqJk7r+hHW6k9+nxijHFj6YJ1+4ElpH/PwWPsqwVIshQxEC
# vJKfo3OfN3a8Mn6Hog5kXJl5dMb0vJOpWQ9UhmG2m9UUZ9847wSlbW0vMHL0puuT
# so0365vilPO5JkapEXcFXdc3LDxXW8BR5NHyaN3VmvfD/qAqe4BiBx2+WAxsolTJ
# Q5IMjG5tIN7WE6VJdUAm6EIgbuFfvG1KiWQJLHkLXdTvwdUTqX9JQYswfvoCwvHR
# h+I2mZX+/iH5HKLcaxqW8b9JnHCtfMSBZqLdI3nGIBw48tRul8lbrg0mJzGCAgIw
# ggH+AgEBMGEwWjELMAkGA1UEBhMCVVMxGDAWBgNVBAoMD1UuUy4gR292ZXJubWVu
# dDEMMAoGA1UECwwDRG9EMQwwCgYDVQQLDANQS0kxFTATBgNVBAMMDERPRCBJRCBD
# QS00OQIDBPTVMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAA
# MBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgor
# BgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQ+si41yFOJsefLzbri1KL6x/navTAN
# BgkqhkiG9w0BAQEFAASCAQCRjLp9N9TPQ7XhKFrnrYvxcxoiTpKzXScJ8oxaBsf7
# q6LJeImnExhZF8Z/HhIIN7dpki17R8TFV0c71XHR0B2MEj+dJM8oyGWLbJK/OkzN
# XbB232B5lqTiKYgGNvq2gH5CK67U2dV4TIBDOy/Bs6y5vUuaBPvgU87kYLwAYfOc
# IOsxMdQ1J1fK9u+7zXuM4TV5+GYtmJQsZK9vP3gCt6Lq/PEzsDoELPKZx+l5aUai
# iC0yFuviCeF6lkaIuma6Hd9K0fik8RWkza/kCnoeY1VH0H1BQwpDh0E5W3+35Dvb
# tSdHcWQ5fVEZkB1SmTNU0VU13FEgIek1BG3eQXP/Il6j
# SIG # End signature block
