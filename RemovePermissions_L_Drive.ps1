<#
#####################################################################################
Name    :   RemovePermissions_L_Drive.ps1
Purpose :   Remove improper permissions on L Drive
Created :   9/25/2018
Author  :   Matthew T Wurtz
Company :   189th Communications Flight / AR Air National Guard
#####################################################################################
#>

$Path = Read-Host "Enter Path"
$FullDir = Get-ChildItem $Path -Force | ?{ $_.PSIsContainer } # Identifies only folders. Comment out PSIsContainer to include all files
# Count number of directories for progress bar
$DirCount = ($FullDir | measure-object).count
$i = 0

Foreach($dir in $fulldir){
    $CurDir = $Path + "\" + $dir.Name
    $acl = Get-ACL $CurDir
    $rules = $acl.access | Where-Object { 
        (-not $_.IsInherited) -and 
        ($_.IdentityReference -like "Area52\189 CF NCC Administrators" -or 
        $_.IdentityReference -like "NT Authority\System" -or
        $_.IdentityReference -like "BUILTIN\Administrators" -or
        $_.IdentityReference -like "Area52\??????????.adm" -or
        $_.IdentityReference -like "S-1-5-*" -or
        $_.IdentityReference -like "Creator Owner")
    }
            $CurDir
            $Rules
        ForEach($rule in $rules) {
            $acl.RemoveAccessRule($rule) | Out-Null
            Set-ACL -Path $CurDir -AclObject $acl
        }

    # Progress bar
        $i += 1
        $progress = (($i / $DirCount)*100).tostring("##.##")
        Write-Progress -Activity "Scanning Directory.." -Status $progress% -PercentComplete $progress
}