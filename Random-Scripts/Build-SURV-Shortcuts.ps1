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
# Build shortcuts
$shortcutLocation = "\\corpis\Tempstore\wurtzm\test"
$iconPath = "C:\Windows\System32\imageres.dll,5"
$pathValid = @()

# Path for CSV of shortcuts failed to create
$outFile = "C:\Users\wurtzmt-a\Desktop\NoShare.txt"

# Build arrays and zero variables
$winrmFailed = @()
$storeNumsTable = @()
$storeNumBlank = @()
$i = 1

# Pull list of computer names
$OUs = "OU=SURV,OU=Shared_Use,OU=Endpoints,DC=dds,DC=dillards,DC=net",
       "OU=SURV,OU=Shared_Use,OU=Win11,OU=Endpoints,DC=dds,DC=dillards,DC=net",
       "OU=SURV,OU=Shared_Use,OU=WildWest,OU=Endpoints,DC=dds,DC=dillards,DC=net"
$computers = foreach ( $OU in $OUs ) {
    Get-ADComputer -SearchBase $OU -filter * | select -ExpandProperty name
}


# Get StoreNum and build list of WinRM failed
foreach ( $computer in $computers ){
    Write-Host "Pulling info for" $i "of" $computers.count
    try {
        # winrm solution
        #$storeNumPulled = Invoke-Command -ComputerName $computer -ScriptBlock{ (ls env:storeNum -ErrorAction SilentlyContinue).value } -erroraction stop
        # aduc solution
        $storeNumPulled = Get-ADComputer $computer -Properties ExtensionAttribute6 | select -ExpandProperty ExtensionAttribute6
        if ( $storeNumPulled -ne $null -and $storeNumPulled -ne '' ){
            $storeNumsTable += [PSCustomObject]@{ # ensure blank env:storeNum variables are left out
                ComputerName = $computer
                StoreNumber  = $storeNumPulled
                URI          = $computer.Substring(1,4) + "_corp"
                Share        = "\\" + $computer + "\" + $computer.Substring(1,4) + "_corp"
            }
        }
        else{
            $storeNumBlank += "StNum Blank $computer`n" # store blank env:storeNum variables
        }
    } catch{
        $winrmFailed += [PSCustomObject]@{ # store computers failed to connect to
            ComputerName = $computer
            StoreNumber  = "Error: $( $computer.Exception.Message )"
        }
    }
    $i++
}

# Append CSV with computernames unable to pull StNum
$storeNumBlank >> $outFile

# Reset counter
$i = 1

# Test-Path on all share locations
foreach ( $store in $storeNumsTable ){
    Write-host "Testing path $i of" $storeNumsTable.count
    if ( Test-Path $store.Share ){ 
        $pathValid += $store
    }
    else{ # Share doesn't exist
        Write-Host "Failed to create share for" $store.Share -ForegroundColor Cyan
        "Share doesn't exist $store" >> $outFile
    }
    $i++
}

# Reassign array to remove computernames where share couldn't be accessed
$storeNumsTable = $pathValid

# Duplicate store numbers
$dupeGroups = $storeNumsTable | group storenumber | where count -gt 1

foreach ( $group in $dupeGroups ){
    $counter = 1
    foreach  ( $store in $group.group ){
        # Construct new name
        $newName = "{0}_{1:D2}" -f $store.StoreNumber, $counter
        
        # Rename store number
        $store.StoreNumber = $newName

        # Increment counter
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