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
clear
# Build Variables
$shortcutLocation = "D:\SurvShortcuts"
If ( -not ( Test-Path $shortcutLocation )){
    mkdir $shortcutLocation
}
$iconPath = "C:\Windows\System32\imageres.dll,5"
$pathValid = @()

# Path for CSV of shortcuts failed to create
$logFile = "D:\SurvShortcuts\NoShare.txt"
If ( Test-Path $logFile ){
    Remove-Item $logFile -Force
}

# Build arrays and zero variables
$winrmFailed = @()
$storeNumsTable = @()
$storeNumBlank = @()
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

# Get info on each machine from ADSI
Write-Host "Getting machine info from ADSI." -ForegroundColor Yellow
foreach ( $computer in $computers ){
    $filter = "(&(objectClass=computer)(sAMAccountName=$computer`$))"
    $searcher = [ADSISearcher]::new()
    $searcher.Filter = $filter
    $searcher.PropertiesToLoad.Add("extensionAttribute6") | Out-Null
    $searcher.PropertiesToLoad.Add("sAMAccountName") | Out-Null
    $result = $searcher.FindOne()

    # Build custom PS object
    if ( $result -and $result.Properties["extensionAttribute6"] ){
        $storeNum = $result.Properties["extensionAttribute6"][0]
        $storeNumsTable += [PSCustomObject]@{ # ensure blank env:storeNum variables are left out
            ComputerName = $computer
            StoreNumber  = $storeNum
            URI          = $computer.Substring(1,4)  + "_corp"
            Share        = "\\" + $computer + "\" + $computer.Substring(1,4)  + "_corp"
        }
    }
    else{
        $storeNumBlank += "StNum Blank $computer`n" # store blank env:storeNum variables
    }
    $i++
}

# Append CSV with computernames unable to pull StNum
$storeNumBlank >> $logFile

# Reset counter
$i = 1

# Test-Path on all share locations
Write-Host "Testing share paths before creating." -ForegroundColor Yellow
foreach ( $store in $storeNumsTable ){
    Write-host "Testing path $i of" $storeNumsTable.count
    if ( Test-Path $store.Share ){ 
        $pathValid += $store
    }
    else{ # Share doesn't exist
        Write-Host "Failed to create shortcut for" $store.Share -ForegroundColor Cyan
        "Share doesn't exist " + $store.share >> $logFile
    }
    $i++
}

# Reassign array to remove computernames where share couldn't be accessed
$storeNumsTable = $pathValid

# Duplicate store numbers
Write-Host "Checking for duplicate store numbers and separating." -ForegroundColor Yellow
$dupeGroups = $storeNumsTable | group storenumber | where count -gt 1

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