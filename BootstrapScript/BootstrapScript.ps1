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
Overwolf    (separate install)
Nvidia Geforce Experience    (separate install)
Canon Printer Drivers   (gonna be super complex)
KDAN PDF Reader / Liquid Text Editor    (decide which one)
#>

<# Matt's Apps to Install at Home & Work
Git.Git
Corsair.iCUE.5
Spotify.Spotify
AgileBits.1Password
VSCodium.VSCodium
Notepad++.Notepad++
Microsoft.WindowsTerminal
RuckZuck    (separate install)
Devolutions.RemoteDesktopManager    (work only)
#>

<# Ashley's Apps to Install at Home
#>

function Install { # Universal winget function
    param (
        [string]$id  # Define the app to install
    )
    
    winget install --id=$id  -e

    $found = winget list --id=$id 2>$null | Select-String "$id"
    If ([bool]$found){ # Returns $true if found, $false if not
        Write-Output "$($id.split('.')[1]) installed successfully."
    }
}

function NvidiaGeforce { # Download and install Geforce Exp. Not available in winget
    $downloadURL = "https://www.nvidia.com/en-us/geforce/geforce-experience/download/"
    $downloadPage = Invoke-WebRequest -Uri $downloadURL -UseBasicParsing
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

function Overwolf { # Download and install Overwolf. Not available in winget
    $downloadURL = "https://download.overwolf.com/install/Download?utm_source=web_app_store"
    $installerPath = "$env:TEMP\OverwolfInstaller.exe"
    Invoke-WebRequest -Uri $downloadURL -OutFile $installerPath
    
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

function RuckZuck { # Download and install RuckZuck. Not available in winget
    $downloadURL = "https://github.com/rzander/ruckzuck/releases/latest"
    $downloadPage = Invoke-WebRequest -Uri $downloadURL -UseBasicParsing
    $installerURL = $downloadPage.Links | Where-Object { $_.href -match "RuckZuck.exe" } | Select-Object -First 1 -ExpandProperty href
    
    if ($installerURL) { # Only download and install if valid URL found
        $installerPath = "C:\Program Files (x86)\RuckZuck"
        If( -not ( Test-Path $installerPath )){
            mkdir $installerPath
        }
        Invoke-WebRequest -Uri $installerURL -OutFile $installerPath
    }

    $found = Test-Path "$installerPath\RuckZuck.exe"
    If($found){ # Verify installed
        $targetPath = "$installerPath\ruckzuck.exe"
        $shortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "RuckZuck.lnk")
        
        $WScriptShell = New-Object -ComObject WScript.Shell
        $shortcut = $WScriptShell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $targetPath
        $shortcut.Save()
        
        Write-Output "RuckZuck installed successfully."
    } else {
        Write-Output "Failed to retrieve the latest RuckZuck."
    }    
}

<# Matt's Settings
Green cursor
Cursor size 3 or 4  (depends on resolution)
Zoom and font size  (depends on resolution)
Short Date
Short Time
Long Time
Disable Recall app/services
PowerShell Profile
#>

<# Ashley's Settings
#>

<# Chris Titus tweaks
Numlock on boot
Turn on/off Recommendations in start menu (Win 11)
Show file extensions
Disable telemetry
Disable homegroup
Disable hibernation
Debloat Edge
Remove OneDrive
Disable Recall
Set services to manual
Add "End Task" to right click
Detailed BSoD ??
Disable storage sense ??
Disable consumer features ??
#>

# Function to open Mouse Pointer Settings UI and set the color & size
function Set-Win10Mouse { # Windows 10
    Start-Process "ms-settings:easeofaccess-mousepointer"  # Open Ease of Access Mouse Settings
    Start-Sleep -Seconds 2  # Wait for settings window to open

    # Send keystrokes to navigate the UI (Requires UIAutomation for full automation)
    Add-Type -AssemblyName System.Windows.Forms

    # Move to Size slider and adjust
    [System.Windows.Forms.SendKeys]::SendWait("{HOME}{RIGHT}{RIGHT}{RIGHT}{ENTER}")  # Moves to size and increases
    Start-Sleep -Seconds 1

    # Move to Color Picker and set custom lime color
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}{HOME}{RIGHT}{RIGHT}{RIGHT}{ENTER}")  # Opens color selection
    Start-Sleep -Seconds 1
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}{HOME}{RIGHT}{ENTER}{LEFT}{ENTER}")  # Selects Lime Green

    # Close the settings window
    Start-Sleep -Seconds 1
    [System.Windows.Forms.SendKeys]::SendWait("%{F4}")  # Alt+F4 to close
}

function Set-Win11Mouse { # Windows 11

}

function Set-MilDateTimeFormat{ # Mil Date and Time Format
    # Set Short Date Format
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sShortDate" -Value "dd-MMM-yy"

    # Set Short Time Format - 24 clock
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sShortTime" -Value "HH:mm"

    # Set Long Time Format - 24 clock with seconds
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sLongTime" -Value "HH:mm:ss"
}

function Disable-Recall { # Disable Recall App/Services (For Windows 11 with Recall)
    $RecallServices = @("RecallSvc", "RecallIndexerSvc")

    foreach ($service in $RecallServices) {
        if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        }
    }
}

function Set-PowerShellProfile { # Load PowerShell Profile

}