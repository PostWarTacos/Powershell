<#
#####################################################################################
Name    :   RemoveProfiles.ps1
Purpose :   Delete user folders as well as registry keys for users that haven't
            logged in for X number of days
Created :   11/7/2018
Author  :   Matthew T Wurtz
#####################################################################################
#>

Clear-host
$MyComputer = "[YOUR COMPUTERNAME]"
Set-Variable -Name "InitialHostsDirectory" -Value "\\$MyComputer\c$\users\[YOUR USERNAME]\Desktop" #Change username if needed
$HostFile = Get-FileName -initialDirectory "$InitialHostsDirectory"
$Computers = Get-Content -Path $HostFile
$TodaysDate = Get-Date -Format FileDate


Function Get-FileName($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

$Days = Read-Host "How many days will dictate a stale account?"

#Count values in test computers for progress bar
$CompCount = ($Computers | measure-object).count
$i = 0

$CountFolders = (get-childitem -Path ("\\$MyComputer\c$\scripts\Delete_Old_Profiles") -recurse | where-object { $_.PSIsContainer -and $_.Name -like "$TodaysDate*" }).count
$NewFolder = $CountFolders + 1

New-Item ("\\$MyComputer\c$\scripts\Delete_Old_Profiles\" + $TodaysDate + "_" + $NewFolder) -type directory
 
# Test connection to each computer before getting the user account info
Clear-Host
    foreach ($Computer in $Computers) {
        Write-host ("Checking Network Connection to:" + $Computer)
            if (Test-Connection -ComputerName $Computer -Quiet -count '1'){
            Add-Content -value $Computer -path ("\\$MyComputer\c$\scripts\Delete_Old_Profiles\" + $TodaysDate + "_" + $NewFolder + "\livePCs.txt")
            }else{
            Add-Content -value $Computer -path ("\\$MyComputer\c$\scripts\Delete_Old_Profiles\" + $TodaysDate + "_" + $NewFolder + "\deadPCs.txt")
            }
    }

#Reassigns Computers variable to just LIVE PCs
$Computers = Get-Content -Path ("\\$MyComputer\c$\scripts\Delete_Old_Profiles\" + $TodaysDate + "_" + $NewFolder + "\livePCs.txt")

    foreach ($Computer in $Computers) {
        write-host
        write-host 
        Write-Host ("Filtering for stale user profiles older than $Days days on $Computer")

        $i += 1

        #Determine what profiles are old              
        $delete = Get-childItem -Path ("\\$Computer\C$\Users") | ? {$_.Name -notlike "*USAF_Admin*" -and  $_.Name -notlike "*Public*" -and  $_.Name -notlike "*ADMIN*" -and  $_.Name -notlike "*Default*"} | `
        select  Name,LastWriteTime | Where {$_.LastWriteTime -lt $(Get-Date).AddDays(-$Days)}
   
        if ($delete -eq $null){Write-Host  ("No stale user profiles older than $Days days where found on $Computer") -foregroundcolor Green}
        
        else {

            ## Find all sessions
            $Sessions =  Invoke-Command -ComputerName $Computer -ScriptBlock { quser }
            $SessionIDs = $Sessions | Select -skip 1
            ## Parse the session IDs from the output
            $SessionIDsCount = ($SessionIDs | measure-object).count
            Write-Host "Found $SessionIDsCount user login(s) on computer."
            Write-Host
            
            If ($SessionIDs){
                ## Loop through each session ID and pass each to the logoff command
                Foreach ($Session in $SessionIDs) {
                    $EDIPI = ($Session -split ' +')[1]
                    $UniqueSessionID = ($Session -split ' +')[2]
                    $Username = Get-ADUser -SearchBase $Users_OU -Filter "gigID -eq '$EDIPI'"
                
                    if($Session -like '*console*'){
                        ## Skipping user. This is the active session
                    }
                    Else{
                        Write-Host "Logging off $Username..."
                        logoff $UniqueSessionID /server:$Computer
                    }
                }
            }
            #Outputs list of user accounts that will be deleted to CSV file
            $delete | Export-Csv ("\\$MyComputer\c$\scripts\Delete_Old_Profiles\" + $TodaysDate + "_" + $NewFolder + "\" + $Computer + "_Pre_Removal_list.csv")
            
            $delete = $delete.name

            $users = Get-WmiObject Win32_UserProfile -ComputerName $Computer;

            $i2 = 0

            $DeleteCount = ($Delete | measure-object).count

            $UsersCount = ($Users | measure-object).count

            # If you have any profiles you want to explicitly ignore, add them here.
            $skip  = @("administrator","usaf_admin","public","default");

            Write-Host

            Write-Host ("$DeleteCount profiles found older than $Days days. Deleting old profiles...") -ForegroundColor Magenta

            Write-Host

            foreach( $user in $users ) {

                ## Progress bar ##
                $i2 += 1
                $progress2 = (($i2 / $UsersCount)*100).tostring("##.##")
                Write-Progress -Activity "Profile Deletion on $Computer ($i of $CompCount). Deleting profile $i2 of $UsersCount..." #-Status $progress2%

                # Normalize profile name.
                $UserName = (Split-Path $user.LocalPath -Leaf).ToLower()
                $UserPath = "\\$Computer\C$\Users\$Username"
                $UserSID = $User.SID

                # If the profile name was found in the skip list, don't process it.
                if( $skip -contains $userPath ) {
                    Write-Host "Skipping $UserName from ignore list.";
                    Write-Host
                    continue;
                }

                # You can't delete the profile of the currently logged-in user, so skip it.
                if( $UserName -eq $env:username ) {
                    Write-Host "Skipping $UserName because it belongs to the current user.";
                    Write-Host
                    continue;
                }

                # If the profile belongs to a "special" account (network/system), skip it.
                if( $user.Special -eq $true ) {
                    Write-Host "Skipping $UserName because it is a special system account.";
                    Write-Host
                    continue;
                }

                # Check the last write time of the user profile
                if( $delete -contains $UserName ){
                    # If we got this far it's safe to delete.
                    Write-Host "Deleting profile for $UserName...";
                    ## $user.Delete(); # Doesn't work on network 
                    Remove-Item -Path $UserPath -Recurse -Force
                    Invoke-Command -ComputerName $Computer {Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$Using:UserSID" -Recurse -Force}
                    #$userPath # use to display the name of the profile being deleted
                    Write-Host
                    continue;
                }
            }
        }
    }
   
