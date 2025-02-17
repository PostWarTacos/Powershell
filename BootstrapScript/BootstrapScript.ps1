<# Matt's Apps to Install at Home
EpicGames.EpicGamesLauncher
Valve.Steam
Discord.Discord
Brave.Brave
Mozilla.Thunderbird
Gimp.Gimp
Insecure.Nmap
RevoUninstaller.RevoUninstaller
GOG.Galaxy
SteelSeries.GG
Oracle.VirtualBox
PrivateInternetAccess.PrivateInternetAccess
7Zip.7Zip
Overwolf    (Separate install)
Nvidia Geforce Experience    (Separate install)
Canon Printer Drivers   (Gonna be super complex)
KDAN PDF Reader / Liquid Text Editor    (Decide which one)
#>

<# Matt's Apps to Install at Home & Work
Git.Git
Corsair.iCUE.5
Spotify.Spotify
AgileBits.1Password
VSCodium.VSCodium
Notepad++.Notepad++
Microsoft.WindowsTerminal
RuckZuck    (Separate install)
Devolutions.RemoteDesktopManager    (work only)
#>

<# Ashley's Apps to Install at Home
#>

function Install {
    param (
        [string]$id  # Define the app to install
    )
    
    winget install --id=$id  -e

    $found = winget list --id=$id 2>$null | Select-String "$id"
    If ([bool]$found){ # Returns $true if found, $false if not
        Write-Output "$($id.split('.')[1]) installed successfully."
    }
}

function NvidiaGeforce {
    $nvidiaURL = "https://www.nvidia.com/en-us/geforce/geforce-experience/download/"
    $downloadPage = Invoke-WebRequest -Uri $nvidiaURL -UseBasicParsing
    $installerURL = $downloadPage.Links | Where-Object { $_.href -match "GeForce_Experience_v\d+(\.\d+)*.exe" } | Select-Object -First 1 -ExpandProperty href
    
    if ($installerURL) { # Only download and install if valid URL found
        $installerPath = "$env:TEMP\GeForceExperience.exe"
        Invoke-WebRequest -Uri $installerURL -OutFile $installerPath
        If (Test-Path $installerPath){ # Verify downloaded
            Start-Process -FilePath $installerPath -ArgumentList "/silent" -Wait
        }
    }

    $geforceExperience = Get-AppxPackage -Name NVIDIACorp.NVIDIAControlPanel
    If($geforceExperience){ # Verify installed
        Write-Output "NVIDIA GeForce Experience installed successfully."
    } else {
        Write-Output "Failed to retrieve the latest NVIDIA installer."
    }    
}

function Overwolf {
    $installerURL = "https://download.overwolf.com/install/Download?utm_source=web_app_store"
    $installerPath = "$env:USERPROFILE\Downloads\OverwolfInstaller.exe"
    Invoke-WebRequest -Uri $installerURL -OutFile $installerPath
    
    If (Test-Path $installerPath){ # Verify downloaded
        Start-Process -FilePath $installerPath -ArgumentList "/silent" -Wait
    }

    $overwolf = reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s | findstr /I "Overwolf"
    If($overwolf){ # Verify installed
        Write-Output "NVIDIA GeForce Experience installed successfully."
    } else {
        Write-Output "Failed to retrieve the latest NVIDIA installer."
    } 
}


<# Matt's Settings
Green cursor
Cursor size 3
Short Date
Short Time
Long Time
Disable Recall app/services
Chris Titus tweaks
#>

<# Ashley's Settings
#>