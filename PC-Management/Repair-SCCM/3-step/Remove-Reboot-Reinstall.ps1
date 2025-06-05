Import-Module C:\Users\wurtzmt-a\Documents\Coding\Powershell\TestingScripts.psm1

$computer = Read-host "Enter Computername"
$remove = "C:\Users\wurtzmt-a\Documents\Coding\Powershell\Remove-SCCM.ps1"
$reinstall = "C:\Users\wurtzmt-a\Documents\Coding\Powershell\reinstall-sccm.ps1"

# Uninstall and Remove
try {
    $exitCode = Invoke-script -computername $computer -filepath $remove -ErrorAction stop
}
catch{
    $EXIT_SUCCESS = 0
    $EXIT_ERROR_COUNT = 1
    $EXIT_INTERACTION_REQ = 2

    switch ($exitCode) {
        $EXIT_SUCCESS{
            # Do nothing. Continue script
        }
        $EXIT_ERROR_COUNT {
            write-host "Non-critical error(s). Please investigate."
            exit 101
        }
        $EXIT_INTERACTION_REQ {
            write-host "User interaction is required."
            exit 102
        }
        default {
            exit $exitCode
        }
    }
}

# File Check
$fileCheck = $null
$fileCheck = Invoke-Command $computer {
    # Check files
    function Get-ExeVersion {
        param (
            [string]$ExePath
        )
        try {
            return ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($ExePath)).FileVersion
        }
        catch {
            return $null
        }
    }

    $correctVersion = "5.00.9132.1011"
    $targetPath = "C:\drivers\ccm\ccmsetup"
    $valid = $false

    $locations = @(
        @{ Path = "C:\drivers\ccm\ccmsetup"; Action = { Write-Host "Correct location and version. Doing nothing." } },
    
        @{ Path = "C:\drivers\ccm\client"; Action = {
            Write-Host "Renaming client to ccmsetup..."
            Rename-Item -Path "C:\drivers\ccm\client" -NewName "ccmsetup" -Force
        }},
    
        @{ Path = "C:\drivers\ccmsetup"; Action = {
            Write-Host "Moving contents to $targetPath..."
            if ( -not ( Test-Path $targetPath )) { New-Item -ItemType Directory -Path $targetPath | Out-Null }
            Move-Item -Path "C:\drivers\ccmsetup\*" -Destination $targetPath -Force
            Remove-Item -Path "C:\drivers\ccmsetup" -Recurse -Force
        }},
    
        @{ Path = "C:\drivers\ccm"; Action = {
            Write-Host "Moving contents to $targetPath..."
            if ( -not ( Test-Path $targetPath )) { New-Item -ItemType Directory -Path $targetPath | Out-Null }
            Move-Item -Path "C:\drivers\ccm\*" -Destination $targetPath -Force
        }}
    )

    foreach ( $entry in $locations ) {
        $exePath = Join-Path $entry.Path "ccmsetup.exe"

        if ( Test-Path $exePath ) {
            $ver = Get-ExeVersion $exePath

            if ( $ver -eq $correctVersion ) {
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
        #write-host "Rebooting computer to complete uninstall."
        #restart-computer -force
    }

    Write-Host "Valid installer prepared. Proceeding..."
}

if ( $fileCheck -eq "Not Found" ){
    write-host "Copying files from server."
    $source = "\\scanz223\SMS_DDS\Client"
    $destination = "\\$computer\C$\drivers\ccm\ccmsetup"
    #robocopy $source $destination /E /Z /MT:4 /R:2 /W:5 /NP /NFL /NDL /NJH /NJS
    robocopy $source $destination /E /Z /MT:4 /R:1 /W:2 /NP /V #/TEE /LOG+:C:\drivers\ccm\robocopy_perf.log
    write-host "Copy complete."
    #write-host "Exiting session."
    #exit
}

# Reboot and Wait
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

Start-Sleep -Seconds 300

# Reinstall
try {
    $exitCode = Invoke-script -computername $computer -filepath $reinstall -ErrorAction stop
}
catch{
    $EXIT_SUCCESS = 0
    $EXIT_HEALTH_CHECK = 1

    switch ($exitCode) {
        $EXIT_SUCCESS{
            # Do nothing. Continue script
        }
        $EXIT_HEALTH_CHECK {
            exit 201
        }
        default {
            exit $exitCode
        }
    }
}
 