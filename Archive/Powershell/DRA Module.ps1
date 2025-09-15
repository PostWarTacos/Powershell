import-module "C:\Program Files (x86)\WindowsPowerShell\Modules\DRA"

$Groupname = Read-Host "Enter Group Name"

$CurrentUsers = Get-NKAGGroupMembers -GroupName $Groupname

$UsersToNotDelete = read-host "Enter Users not to delete"

foreach ($User in $CurrentUsers){
    if ($user -like $UsersToNotDelete){
        #Do nothing
    }
    else{
        $user = $User.GroupMembers
        Remove-NKAGGroupMembers -GroupName $Groupname -Edipi $User
    }
}