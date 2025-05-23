Clear-Host
$targets = get-content "$env:USERPROFILE\desktop\targets.txt"
$source = "\\scanz223\SMS_DDS\Client"
write-host "There are $($targets.count) targets in targets.txt"

# Test connections
$alives = foreach ( $t in $targets ){
    Write-Host "Testing connection to $t."
    if ( Test-Connection -Quiet -Count 2 -ComputerName $t){
        Write-Output $t
    }
}

Write-host "Of the original $($targets.count) targets, $($alives.count) were found to be alive."

$i = 1

foreach ( $t in $alives ){
    write-host "$t ( $i of $($alives.count))"
    $destination = "\\$t\C$\drivers\ccmsetup"
    if ( Test-Path $destination -PathType Leaf ) {
        Write-host "Found leaf matching destination name on $t. Removing it."
        Remove-Item -Path $destination -Force | Out-Null
    }
    if ( -not ( Test-Path $destination -PathType Container )) {
        Write-host "Destination not found on $t. Creating directory."
        New-Item -Path $destination -Force -ItemType Directory | Out-Null
    }
    
    # Robocopy
    robocopy $source $destination /E /Z /MT:8 /R:2 /W:5 /NP /NFL /NDL /NJH /NJS

    #FastCopy

    $i++
}