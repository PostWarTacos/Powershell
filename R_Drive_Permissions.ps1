<#
#####################################################################################
Name    :   R_Drive_Permissions.ps1
Purpose :   Uses folder names to determine permissions that should be applied
Created :   05/29/2019
Author  :   Matthew T Wurtz
Company :   189th Communications Flight / AR Air National Guard
#####################################################################################
#>
Clear-Host
#Path to scan and find folders
$OrigPath = "\\189AW-FS-03\Records\(PA)_Notice_and_Consent"

#Searching for folders
$Path = Get-ChildItem "$OrigPath" -Force | ?{ $_.PSIsContainer }

#Load VB library to complete trim action
[reflection.assembly]::LoadWithPartialName( "microsoft.visualbasic" )
Clear-Host

foreach($UserFolder in $Path){
    
    #Create variable for full filepath
    $CurDir = $OrigPath + "\" + $UserFolder
    $CurDir
    If ( $CurDir -like '\\189AW-FS-03\Records\(PA)_Notice_and_Consent\_*' ){
        #
        #do nothing
        #
    }
    elseif ( $CurDir -like '*.adm'){ # ADMIN ACCOUNTS
        Try{
        #Get the current ACL from the folder
        $ACL = Get-Acl $CurDir

        #Get current folder name
        $UserName = ( Split-Path $UserFolder.Name -Leaf ).ToLower()
    
        #Remove periods from variable created from folder name
        $UserNameTrimmed = $UserName  -replace '[.]',''
    
        #Create variable from EDI and PCC
        $AdmPre2k = [microsoft.visualbasic.strings]::right( $UserNameTrimmed,14 )
        $Pre2kUserName = [microsoft.visualbasic.strings]::Left( $AdmPre2k,11 )

        #Create rule for modify rights for user
        $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule( "Area52\$Pre2kUserName","Modify", "ContainerInherit, ObjectInherit", "None", "Allow" )

        #Add rule to folder
        $ACL.AddAccessRule( $Rule )
        Set-ACL -Path $CurDir -AclObject $ACL
        }
        Catch { $CurDir >> C:\Permission_Errors.txt }
    }
    else{
    Try{
        #Get the current ACL from the folder
        $ACL = Get-Acl $CurDir

        #Get current folder name
        $UserName = ( Split-Path $UserFolder.Name -Leaf ).ToLower()
    
        #Remove periods from variable created from folder name
        $UserNameTrimmed = $UserName  -replace '[.]',''
    
        #Create variable from EDI and PCC
        $Pre2kUserName = [microsoft.visualbasic.strings]::right( $UserNameTrimmed,11 )
    
        #Create rule for modify rights for user
        $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule( "Area52\$Pre2kUserName","Modify", "ContainerInherit, ObjectInherit", "None", "Allow" )
    
        #Add rule to folder
        $ACL.AddAccessRule( $Rule )
        Set-ACL -Path $CurDir -AclObject $ACL
        }
        Catch { $CurDir >> C:\Permission_Errors.txt }
    }
}

