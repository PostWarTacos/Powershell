Import-Module C:\Users\wurtzmt-a\Documents\Coding\Powershell\TestingScripts.psm1

$computer = Read-host "Enter Computername"
$remove = "C:\Users\wurtzmt-a\Documents\Coding\Powershell\Remove-SCCM.ps1"
$reinstall = "C:\Users\wurtzmt-a\Documents\Coding\Powershell\reinstall-sccm.ps1"

# remove
Invoke-script -computername $computer -filepath $remove

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

    $correctVersion = "5.00.9132.1023"
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
        Write-Warning "No valid ccmsetup.exe found. Exiting."
        return "Not Found"
        write-host "Rebooting computer to complete uninstall."
        restart-computer -force
    }

    Write-Host "Valid installer prepared. Proceeding..."
}

if ( $fileCheck -eq "Not Found" ){
    exit
}

# reboot and wait
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

# reinstall
Invoke-script -computername $computer -filepath $reinstall
