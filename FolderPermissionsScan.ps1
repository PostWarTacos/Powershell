 <#
#####################################################################################
Name    :   FolderPermissionsScan.ps1
Purpose :   Scan folder path for Individual users with folder permissions, Full Control
            persmissions, and SIDs that need to be removed. Exports info to CSV
Created :   11/7/2018
Author  :   Matthew T Wurtz
Company :   189th Communications Flight / AR Air National Guard
#####################################################################################
#>

Clear-host
$OrigPath = Read-Host "Enter the path you wish to check" # User specifies the path to be scanned
$OutputFileName = (Split-Path $OrigPath -Leaf).ToString() # Folder name of folder to be scanned assigned to variable, so it can be added to the name of the Output File

If ((Test-Path \\nkagw-112626\c$\Scripts) -eq $false)
{
    New-Item -ItemType Directory -Path \\nkagw-112626\c$ -Name Scripts
}

If ((Test-Path \\nkagw-112626\c$\Scripts\FolderPermissions) -eq $false)
{
    New-Item -ItemType Directory -Path \\nkagw-112626\c$ -Name FolderPermissions
}

$Path = Get-ChildItem -Recurse "$OrigPath" -Force | ?{ $_.PSIsContainer } # Identifies only folders. Comment out PSIsContainer to include all files

# Delete Old Report
        If ((Test-Path \\NKAGW-112626\C$\Scripts\FolderPermissions\$OutputFileName) -eq $false)
        {
            New-Item -ItemType Directory -Path \\NKAGW-112626\C$\Scripts\FolderPermissions -Name $OutputFileName
        }
        Elseif ((Test-Path \\NKAGW-112626\C$\Scripts\FolderPermissions\$OutputFileName) -eq $true)
        {
            Write-Host ""
            $Caption = "Delete Old Files";
            $Message = "Do you want to delete the old scan files for this folder?";
            $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes";
            $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No";
            $Choices = [System.Management.Automation.Host.ChoiceDescription[]]($Yes,$No);
            $Answer = $host.ui.PromptForChoice($Caption,$Message,$Choices,-1)
            Switch ($Answer)
	            {
	            0
		            {
    		            Remove-Item -Path \\NKAGW-112626\C$\Scripts\FolderPermissions\$OutputFileName -Force -Recurse
                        New-Item -ItemType Directory -Path \\NKAGW-112626\C$\Scripts\FolderPermissions -Name $OutputFileName
		            }
	            1 
		            {
                        Write-host ""
		                Write-host "Before continuing, move old scan files to different location." -ForegroundColor Red
                        Write-host ""
                        Pause
		            }
	            }
        }

# Count number of directories for progress bar
$DirCount = ($Path | measure-object).count
$i = 0
$FullCount = 0
$UserCount = 0
$DupCount = 0

    foreach ($Dir in $Path) {     

##
##  FULL CONTROL ACCESS
##

    # Outputs just the folder/file path and name to PS
        $Dir.FullName
        
    # Tests all account names that have FullControl that are not System, CF NCC, or Administrators
        $FullAccess = $Dir.GetAccessControl('Access').Access | where FileSystemRights -eq FullControl | Select IdentityReference |
            ? {$_.IdentityReference -notlike "*NT AUTHORITY\SYSTEM*" -and $_.IdentityReference -notlike "*AREA52\189 CF NCC Administrators*" -and $_.IdentityReference -notlike "*BUILTIN\Administrators*"}
    
    # Tests if variable returned anything aside from System, CF NCC, or Administrators
        if ($FullAccess) {
    
    # Output FullName and FullControl ACL to CSV file
            $Dir.FullName >> \\nkagw-112626\c$\scripts\FolderPermissions\$OutputFileName\$OutputFileName"_FullFolderPermissions.csv"
    
    # Full command needs to be used, because we cannot output a variable of this size
            $Dir.GetAccessControl('Access').Access | where FileSystemRights -eq FullControl | Select IdentityReference |
                ? {$_.IdentityReference -notlike "*NT AUTHORITY\SYSTEM*" -and $_.IdentityReference -notlike "*AREA52\189 CF NCC Administrators*" -and $_.IdentityReference -notlike "*BUILTIN\Administrators*"} >> \\nkagw-112626\c$\scripts\FolderPermissions\$OutputFileName\$OutputFileName"_FullFolderPermissions.csv"

    # Count how many folders returned positively
        $FullCount += 1

        }
        
##
##  USER INDIVIDUAL ACCESS  
##

    # Tests all account names that have individual user access that are not System, CF NCC, or Administrators
        $UserAccess = $Dir.GetAccessControl('Access').Access | Select IdentityReference |
            ? {$_.IdentityReference -notlike "*NT AUTHORITY\SYSTEM*" -and $_.IdentityReference -notlike "*AREA52\189 CF NCC Administrators*" -and $_.IdentityReference -notlike "*BUILTIN\Administrators*" `
            -and $_.IdentityReference -like "Area52\*.adm" -or $_.IdentityReference -like "S-1-5-*" -or $_.IdentityReference -like "Creator Owner*" `
            -or $_.IdentityReference -like "Area52\??????????N" -or $_.IdentityReference -like "Area52\??????????C" -or $_.IdentityReference -like "Area52\??????????A" -or $_.IdentityReference -like "Area52\??????????V" `
            -or $_.IdentityReference -like "Area52\??????????E" -or $_.IdentityReference -like "Area52\??????????K" -or $_.IdentityReference -like "Area52\??????????M" }
    
    # Tests if variable returned anything aside from System, CF NCC, or Administrators
        if ($UserAccess) {
    
    # Output FullName and individual user access ACL to CSV file
            $Dir.FullName >> \\nkagw-112626\c$\scripts\FolderPermissions\$OutputFileName\$OutputFileName"_UserFolderPermissions.csv"
    
    # Full command needs to be used, because we cannot output a variable of this size
            $Dir.GetAccessControl('Access').Access | Select IdentityReference |
                ? {$_.IdentityReference -notlike "*NT AUTHORITY\SYSTEM*" -and $_.IdentityReference -notlike "*AREA52\189 CF NCC Administrators*" -and $_.IdentityReference -notlike "*BUILTIN\Administrators*" `
                -and $_.IdentityReference -like "Area52\*.adm" -or $_.IdentityReference -like "S-1-5-*" -or $_.IdentityReference -like "Creator Owner*" `
                -or $_.IdentityReference -like "Area52\??????????N" -or $_.IdentityReference -like "Area52\??????????C" -or $_.IdentityReference -like "Area52\??????????A" -or $_.IdentityReference -like "Area52\??????????V" `
                -or $_.IdentityReference -like "Area52\??????????E" -or $_.IdentityReference -like "Area52\??????????K" -or $_.IdentityReference -like "Area52\??????????M" } >> \\nkagw-112626\c$\scripts\FolderPermissions\$OutputFileName\$OutputFileName"_UserFolderPermissions.csv"

    # Count how many folders returned positively
        $UserCount += 1

        }

##
##  DUPLICATE PERMISSIONS  
##
   
    # Create list of all permissions in ACL
        $PermList = $Dir.GetAccessControl('Access').Access | Select IdentityReference

    # Build array to calculate which permissions are applied more than once
        $ListArray = @($PermList)
        $ht = @{}
        $ListArray| foreach {$ht["$_"] += 1}
        $ht.keys | where {$ht["$_"] -gt 1} | foreach {write-host "Duplicate found $_"}
        $Duplicates = $ht.keys | where {$ht["$_"] -gt 1}

    # If there are duplicate permissions, export folder name and list duplicates
        If ($Duplicates) {
            $Dir.FullName >> \\nkagw-112626\c$\scripts\FolderPermissions\$OutputFileName\$OutputFileName"_DuplicateFolderPermissions.csv"
            $Duplicates.trimstart("@{IdentityReference=").trimstart("AREA52\").trimend("}").trim() >> \\nkagw-112626\c$\scripts\FolderPermissions\$OutputFileName\$OutputFileName"_DuplicateFolderPermissions.csv"
    
    # Output blank space to CSV
            " " >> \\nkagw-112626\c$\scripts\FolderPermissions\$OutputFileName\$OutputFileName"_DuplicateFolderPermissions.csv"
            " " >> \\nkagw-112626\c$\scripts\FolderPermissions\$OutputFileName\$OutputFileName"_DuplicateFolderPermissions.csv"
    
    # Count how many folders returned positively
            $DupCount += 1

        }

    # Trim excess from User/Group name and output to CSV
        #$ht.keys.trimstart("@{IdentityReference=").trimstart("AREA52\").trimend("}").trim()

    # Progress bar
        $i += 1
        $progress = (($i / $DirCount)*100).tostring("##.##")
        Write-Progress -Activity "Scanning Directory.." -Status $progress% -PercentComplete $progress
    }

Write-host 
Write-host ("Folder Access Scan for " + $OrigPath + " complete. Get Report at C:\Scripts\") -foregroundcolor Green
Write-host 
Write-host ("Returned " + $FullCount + " folders with improper Full Control Access") -foregroundcolor Green
Write-host 
Write-host ("Returned " + $UserCount + " folders with User Individual Access") -foregroundcolor Green
Write-host 
Write-host ("Returned " + $DupCount + " folders with Duplicate Permissions") -foregroundcolor Green

# Returns single folder
# ((Get-Item $path).GetAccessControl('Access').Access) | where FileSystemRights -eq FullControl | Select IdentityReference