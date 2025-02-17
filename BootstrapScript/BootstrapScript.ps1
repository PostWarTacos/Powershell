<# Apps to Install at Home
Epic
Steam
Discord
Brave browser
Thunderbird
Gimp
nmap
Nvidia Geforce Experience
Revo Uninstaller
GOG Launcher
Steel Series
Virtual Box
Overwolf
Private Internet Access
7Zip
Canon Printer Drivers
KDAN PDF Reader / Liquid Text Editor
#>

function Install {
    winget install --id=$id  -e
    $found = winget list --id=$id 2>$null | Select-String "$id"
    [bool]$found  # Returns $true if found, $false if not
    
    Write-Output "Epic Launcher installed successfully."
}

function NvidiaGeforce {
    $nvidiaURL = "https://www.nvidia.com/en-us/geforce/geforce-experience/download/"
    $downloadPage = Invoke-WebRequest -Uri $nvidiaURL -UseBasicParsing
    $installerURL = $downloadPage.Links | Where-Object { $_.href -match "GeForce_Experience_v\d+(\.\d+)*.exe" } | Select-Object -First 1 -ExpandProperty href
    
    if ($installerURL) {
        $installerPath = "$env:TEMP\GeForceExperience.exe"
        Invoke-WebRequest -Uri $installerURL -OutFile $installerPath
        Start-Process -FilePath $installerPath -ArgumentList "/silent" -Wait
        Write-Output "NVIDIA GeForce Experience installed successfully."
    } else {
        Write-Output "Failed to retrieve the latest NVIDIA installer."
    }    
}

function Overwolf {

}

function Canon {

}


<# Apps to Install on Home & Work
Git
Corsair iCue
Spotify
1Password
RuckZuck
VS Codium
Notepad++
Windows Terminal
Remote Desktop Manager (work only)
#>

<# Settings
Green cursor
Cursor size 3
Short Date
Short Time
Long Time
Disable Recall app/services
Chris Titus tweaks
#>