#######################################################################################
#
#   Build Surveillance Webpage
#   Intent: Connect to ADSI and pull list of surveillance computers, then create a
#       locally hosted webpage with links to view the files on those computers
#   Author: Matthew Wurtz
#   Date: 1/23/2025
#
#######################################################################################

if (test-path C:\Users\wurtzmt-a\Desktop\transcript.txt){
    rm -Force C:\Users\wurtzmt-a\Desktop\transcript.txt
}
Start-Transcript -Path C:\Users\wurtzmt-a\Desktop\transcript.txt

# test machine WCANT-SURVEG87S

# Pull list of computer names
$OUs = "OU=SURV,OU=Shared_Use,OU=Endpoints,DC=dds,DC=dillards,DC=net",
       "OU=SURV,OU=Shared_Use,OU=Win11,OU=Endpoints,DC=dds,DC=dillards,DC=net",
       "OU=SURV,OU=Shared_Use,OU=WildWest,OU=Endpoints,DC=dds,DC=dillards,DC=net"
$computers = foreach ( $OU in $OUs ) {
    Get-ADComputer -SearchBase $OU -filter * | select -ExpandProperty name
}
$outfile = "C:\users\wurtzmt\Desktop\test.html"
$winrmFailed = @()
$storeNumsTable = @()
$storeNumBlank = @()
$divisions = @{}
$i = 0

# Get StoreNum and build list of WinRM failed
foreach ( $computer in $computers ){
    try {
        $storeNumPulled = Invoke-Command -ComputerName $computer -ScriptBlock{ (ls env:storeNum -ErrorAction SilentlyContinue).value } -erroraction stop
        if ( $storeNumPulled -ne $null -and $storeNumPulled -ne '' ){
            $storeNumsTable += [PSCustomObject]@{ # ensure blank env:storeNum variables are left out
                ComputerName = $computer
                StoreNumber  = $storeNumPulled
            }
        }
        else{
            $storeNumBlank += $computer # store blank env:storeNum variables
        }
    } catch{
        $winrmFailed += [PSCustomObject]@{ # store computers failed to connect to
            ComputerName = $computer
            StoreNumber  = "Error: $( $_.Exception.Message )"
        }
    }
    $i += 1
    write-host $i " of " $computers.Count # for troubleshooting
}

# Breakdown store numbers by division
foreach ( $store in $storeNumsTable ){
    # Extract first digit
    $firstDigit = $store.StoreNumber.ToString()[0]

    # Check if group exists, create if not
    if ( -not $divisions.ContainsKey( $firstDigit )){
        $divisions[$firstDigit] = @()
    }

    # Add number to the group
    $divisions[$firstDigit] += $store
}

# Create ordered dictionary
$sortedDivisions = [System.Collections.Specialized.OrderedDictionary]::new()

$divisions.Keys | sort {[int]$_} | ForEach-Object {
    $divisionKey = $_
    $sortedStores = $divisions[$divisionKey] | sort storeNumber
    $sortedDivisions[$divisionKey] = $sortedStores
}


# Build HTML/CSS 
$htmlContent = @"
<html>
<head>
    <title>Surveillance Computer Links</title>
    <style>
        a:hover{
           font-weight:800;
           font-size:20px;
           color:red
        }
    </style>
</head>
<body>
    <h1>Surveillance Computer Links</h1>
    <ul>
"@

# Cycle through computer names to build links
# Include status of remote machine connection
# Stringbuilder for optimization
$stringBuilder = New-Object -TypeName System.Text.StringBuilder
foreach ( $divisionKey in $sortedDivisions.Keys ) {
    [void]$stringBuilder.appendline( "DIVISION " + $divisionkey )
    foreach ( $entry in $sortedDivisions[$divisionKey] ) {
        # Access ComputerName and StoreNumber in each entry
        $computerName = $entry.ComputerName
        $storeNumber = $entry.StoreNumber

        Write-Host "Processing Computer: $computerName with StoreNumber: $storeNumber"
        $share = $computerName.Substring(1,4) + "_corp"
        $link = "file://" + $computerName + "/" + $share
        [void]$stringBuilder.appendline( "     <li><a href='$link'>$storeNumber</a></li>" )
    }
}

# Append the generated links to the HTML content
$htmlContent += $stringBuilder.ToString()

# end html
$htmlContent += @"
    </ul>
</body>
</html>
"@

Set-Content -Path $outfile -Value $htmlContent -Encoding UTF8

# Create scheduled task that runs this script regularly

Stop-Transcript