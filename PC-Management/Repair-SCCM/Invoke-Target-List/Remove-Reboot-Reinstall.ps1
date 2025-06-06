Import-Module C:\Users\wurtzmt-a\Documents\Coding\Powershell\TestingScripts.psm1

# -------------------- VARIABLES -------------------- #

$computer = Read-host "Enter Computername"

# Local URLs
$remove = "C:\Users\wurtzmt-a\Documents\Coding\Powershell\3-step\Remove-SCCM.ps1"
$reinstall = "C:\Users\wurtzmt-a\Documents\Coding\Powershell\3-step\reinstall-sccm.ps1"

# URLs for copying exe to machine
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
 if ( $domain -match "DDS" ) {
    $cpSource = "\\scanz223\SMS_DDS\Client" # DDS
}
elseif ( $domain -match "DPOS" ) {
    $cpSource = "\\slrcp223\SMS_PCI\Client" # PCI
}
$cpDestination = "\\$computer\C$\drivers\ccm\ccmsetup"

# Check exe on target machine
$exeOnSrvr = Join-Path $cpSource "ccmsetup.exe"
$correctVersion = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($exeOnSrvr)).FileVersion
$targetPath = "C:\drivers\ccm\ccmsetup"

# -------------------- Uninstall and Remove -------------------- #

Invoke-script -computername $computer -filepath $remove

# -------------------- File Check -------------------- #

$fileCheck = $null
$fileCheck = Invoke-Command $computer {
    
    $valid = $false

    # Various locations the ccmsetup.exe can be found. Actions to move it to 1 dedicated location.
    $locations = @(
        @{ Path = "C:\drivers\ccm\ccmsetup"; Action = { Write-Host "Correct location and version. Doing nothing." } },
    
        @{ Path = "C:\drivers\ccm\client"; Action = {
            Write-Host "Renaming client to ccmsetup..."
            Rename-Item -Path "C:\drivers\ccm\client" -NewName "ccmsetup" -Force
        }},
    
        @{ Path = "C:\drivers\ccmsetup"; Action = {
            Write-Host "Moving contents to $using:targetPath..."
            if ( -not ( Test-Path $using:targetPath )) { New-Item -ItemType Directory -Path $using:targetPath | Out-Null }
            Move-Item -Path "C:\drivers\ccmsetup\*" -Destination $using:targetPath -Force
            Remove-Item -Path "C:\drivers\ccmsetup" -Recurse -Force
        }},
    
        @{ Path = "C:\drivers\ccm"; Action = {
            Write-Host "Moving contents to $using:targetPath..."
            if ( -not ( Test-Path $using:targetPath )) { New-Item -ItemType Directory -Path $using:targetPath | Out-Null }
            Move-Item -Path "C:\drivers\ccm\*" -Destination $using:targetPath -Force
        }}
    )

    # Checks each location above, verifies version number, and then performs the action if needed 
    foreach ( $entry in $locations ) {
        $exePath = Join-Path $entry.Path "ccmsetup.exe"

        if ( Test-Path $exePath ) {
            $ver = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($exePath)).FileVersion

            if ( $ver -eq $using:correctVersion ) {
                & $entry.Action
                $valid = $true
                break
            } else {
                Write-Warning "$exePath found, but version $ver is invalid. Removing..."
                Remove-Item -Path $exePath -Force
            }
        }
    }

    if ( -not $valid ) {
        return "Not Found"
        Write-Warning "No valid ccmsetup.exe found."
        # write-host "Rebooting computer to complete uninstall."
        # restart-computer -force
    }
}

# Copies files from server if needed
if ( $fileCheck -eq "Not Found" ){
    write-host "Copying files from server."
    # robocopy $cpSource $cpDestination /E /Z /MT:4 /R:2 /W:5 /NP /NFL /NDL /NJH /NJS
    robocopy $cpSource $cpDestination /E /Z /MT:4 /R:1 /W:2 /NP /V
    write-host "Copy complete."
}

# -------------------- Reboot and Wait -------------------- #

$initialBootTime = invoke-command -ComputerName $computer { 
    ( Get-CimInstance -ComputerName $Computer -ClassName Win32_OperatingSystem ).LastBootUpTime
}
Write-Host "Rebooting $computer" -ForegroundColor Cyan
restart-computer -Force -ComputerName $computer

do {
    Start-Sleep -Seconds 60
    try {
        $currentBootTime = ( Get-CimInstance -ComputerName $Computer -ClassName Win32_OperatingSystem -ErrorAction Stop ).LastBootUpTime
    }
    catch {
        $currentBootTime = $initialBootTime
    }
} while ( $currentBootTime -le $initialBootTime )

# Delay to wait for computer to boot
Start-Sleep -Seconds 120

# -------------------- Reinstall -------------------- #

Invoke-script -computername $computer -filepath $reinstall
# Invoke-Command $computer -FilePath $reinstall -Verbose