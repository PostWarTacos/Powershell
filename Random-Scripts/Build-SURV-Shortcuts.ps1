#######################################################################################
#
#   Build Surveillance Shortcuts
#   Intent: Connect to ADSI and pull list of surveillance computers, then create a
#       shortcuts to network shares hosted on each of those computers to view
#       the files on those computers. Shares are test before shortcut links are made.
#   Author: Matthew Wurtz
#   Date: 1/23/2025
#
#######################################################################################
Function Get-SiteInfoFromDDSAPI() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Hostname
    )

    $uri = "https://ssdcorpappsrvt1.dpos.loc/esper/Device/AllStores"
    $header = @{"accept" = "text/plain"}
    $web = Invoke-WebRequest -Uri $uri -Headers $header
    $db = $web.content | ConvertFrom-Json

    $localCode = $($Hostname).substring(1,4)
    $result = $db | Where-Object SiteCode -eq $localCode

    $result | Select-Object StoreNumber
    return $result
}

clear
# Build Variables
$shortcutLocation = "D:\SurvShortcuts"
If ( -not ( Test-Path $shortcutLocation )){
    New-Item -ItemType Directory -Path $shortcutLocation
}
$iconPath = "C:\Windows\System32\imageres.dll,5"
$pathValid = @()

# Path for CSV of shortcuts failed to create
$logFile = "D:\SurvShortcuts\NoShare.txt"
If ( Test-Path $logFile ){
    Remove-Item $logFile -Force
}

# Build arrays and zero variables
$storeNumsTable = @()
$i = 1

# Pull list of computer names
$OUs = @(
    "LDAP://OU=SURV,OU=Shared_Use,OU=Endpoints,DC=dds,DC=dillards,DC=net",
    "LDAP://OU=SURV,OU=Shared_Use,OU=Win11,OU=Endpoints,DC=dds,DC=dillards,DC=net",
    "LDAP://OU=SURV,OU=Shared_Use,OU=WildWest,OU=Endpoints,DC=dds,DC=dillards,DC=net"
)

Write-Host "Searching SURV OUs for SURV machines." -ForegroundColor Yellow
$filter = "(&(objectClass=computer)(sAMAccountName=*))"
$computers = foreach ($OU in $OUs) {
    $searcher = [ADSISearcher]::new()
    $searcher.SearchRoot = [ADSI]$OU
    $searcher.Filter = $filter
    $searcher.PropertiesToLoad.Add("name") | Out-Null
    $searcher.FindAll() | ForEach-Object {
        $_.Properties["name"] | Select-Object -First 1
    }
}   

# Test Connection to all SURV machines
foreach ( $computer in $computers ){
    $alives = if ( Test-Connection -Quiet -Count 2 -ComputerName $computer){
        Write-Output $computer
    }
}

# Overwrite $computers variable with only alive computers
$computers = $alives

# Get info on each machine from ADSI
Write-Host "Getting machine info from ADSI." -ForegroundColor Yellow
foreach ( $computer in $computers ){
    $filter = "(&(objectClass=computer)(sAMAccountName=$computer`$))"
    $searcher = [ADSISearcher]::new()
    $searcher.Filter = $filter
    $searcher.PropertiesToLoad.Add("extensionAttribute6") | Out-Null
    $searcher.PropertiesToLoad.Add("sAMAccountName") | Out-Null
    $result = $searcher.FindOne()

    # Build custom PS object that includes path to share on each computer
    [string]$storeNum = $result.Properties["extensionAttribute6"][0]
    If( $null -eq $storeNum -or $storeNum -eq '' ){
        [string]$storeNum = Get-SiteInfoFromDDSAPI $computer | Select-Object -ExpandProperty StoreNumber -First 1 -ErrorAction SilentlyContinue
        if ( $storeNum.StartsWith('0')) { $storeNum = $storeNum.Substring(1) }
    }
    $storeNumsTable += [PSCustomObject]@{ # ensure blank env:storeNum variables are left out
        ComputerName = $computer
        StoreNumber  = $storeNum
        URI          = $computer.Substring(1,4)  + "_corp"
        Share        = "\\" + $computer + "\" + $computer.Substring(1,4)  + "_corp"
    }
    $i++
}

# Reset counter
$i = 1

# Test-Path on all share locations
Write-Host "Testing share paths before creating." -ForegroundColor Yellow
foreach ( $store in $storeNumsTable ){
    Write-host "Testing path $i of" $storeNumsTable.count
    if ( Test-Path $store.Share ){ 
        $pathValid += $store
    }
    else{ # Failed to create shortcut
        Write-Host "Failed to create shortcut for" $store.Share -ForegroundColor Cyan
        "Failed to create shortcut for " + $store.share >> $logFile
        #-------------------------------------- add code to create share ------------------------------------------------#
        <#
        $UserSAM = $Username.SamAccountName

        New-SmbShare -Name $LDrive$ -Path "F:\$LDrive" -CimSession $Session
        Grant-SmbShareAccess -Name $LDrive$ -AccountName "$UserSAM" -AccessRight Change -Force -CimSession $Session
        Revoke-SmbShareAccess -Name $LDrive$ -AccountName "Everyone" -Force -CimSession $Session

        $LDriveDir = $LDrive.FullName

        #Check folder for access rights
        $Access = ((Get-Item $LDriveDir).GetAccessControl('Access').Access) | Select IdentityReference | ? {$_.IdentityReference -like "*$UserEDI*"}
        
        If(!$Access){

            #Get the current ACL from the folder
            $ACL = Get-Acl \\NKAG-FS-001v\F$\$LDrive

            #Create rule for modify rights for user
            $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule( $UserSAM,"Modify","ContainerInherit, ObjectInherit", "None", "Allow" )

            #Add rule to folder
            $ACL.AddAccessRule( $Rule )
            Set-ACL -Path "\\NKAG-FS-001v\F$\$LDrive" -AclObject $ACL
        }
        #>
    }
    $i++
}

# Reassign array to remove computernames where share couldn't be accessed
$storeNumsTable = $pathValid

#-------------------------------------- add code to modify permissions ------------------------------------------------#

# Duplicate store numbers
Write-Host "Checking for duplicate store numbers and separating." -ForegroundColor Yellow
$dupeGroups = $storeNumsTable | group storenumber | Where-Object count -gt 1

foreach ( $group in $dupeGroups ){
    $counter = 1
    foreach  ( $store in $group.group ){
        # Construct new name
        $newName = "{0}_{1:D2}" -f $store.StoreNumber, $counter      
        # Rename store number
        $store.StoreNumber = $newName
        $counter++
    }
}

# Build shortcuts
foreach ($store in $storeNumsTable) {
    $shortcutName = $store.StoreNumber + ".lnk"
    $shortcutPath = Join-Path -Path $shortcutLocation -ChildPath $shortcutName
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $store.share
    $Shortcut.IconLocation = $iconPath
    $Shortcut.Save()

    Write-Host "Created shortcut: $shortcutPath"
}

Write-Host "Completed creating" $storeNumsTable.count "shortcuts"
