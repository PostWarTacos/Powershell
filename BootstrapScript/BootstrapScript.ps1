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
    
    Write-host "Downloading and installing $($id.split('.')[1])."
    winget install --id=$id  -e

    $found = winget list --id=$id 2>$null | Select-String "$id"
    If ([bool]$found){ # Returns $true if found, $false if not
        Write-Output "$($id.split('.')[1]) installed successfully."
    }
}

function NvidiaGeforce { # Download and install Geforce Exp. Not available in winget
    Write-host "Downloading and installing Nvidia Geforce Experience."
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
    Write-host "Downloading and installing Overwolf."
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
    Write-host "Downloading and installing RuckZuck."
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
Turn on/off Recommendations in start menu (Win 11)
Cursor size 3 or 4  (depends on resolution)
Zoom and font size  (depends on resolution)
Green cursor for Win 10
Green cursor for Win 11
Short Date
Short Time
Long Time
Disable Recall app/services
PowerShell Profile
Numlock on boot
Show file extensions
Disable PowerShell 7 Telemetry
Disable Teredo tunneling protocol
Disable hibernation
Add "End Task" to right click
Detailed BSoD
Disable storage sense
Disable consumer features
#>

<# Ashley's Settings
#>

<# Chris Titus tweaks
Disable telemetry  (NOTE DONE YET)
Remove OneDrive  (NOTE DONE YET)
Set services to manual  (NOTE DONE YET)
SetIPv4 as preferred
Disable homegroup
Debloat Edge
Disable Recall
#>

# Function to open Mouse Pointer Settings UI and set the color & size
function Set-Win10Mouse { # Windows 10
    Write-host "Setting mouse pointer color and size."
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
    Write-host "Setting mouse pointer color and size."
}

function Set-MilDateTimeFormat{ # Mil Date and Time Format
    # Set Short Date Format
    Write-host "Setting short date format to dd-MMM-yy."
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sShortDate" -Value "dd-MMM-yy"
    
    # Set Short Time Format - 24 clock
    Write-host "Setting short time to 24 hour clock."
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sShortTime" -Value "HH:mm"
    
    # Set Long Time Format - 24 clock with seconds    
    Write-host "Setting long time to 24 hour clock with seconds."
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sLongTime" -Value "HH:mm:ss"
}

function Disable-Recall { # Disable Recall App/Services (For Windows 11 with Recall)
    Write-Host "Disabling Recall."
    if (Get-WindowsOptionalFeature -Online -FeatureName Recall) {
        DISM /Online /Disable-Feature /FeatureName:Recall
    } else {
        Write-Host "Recall feature not found, skipping." -ForegroundColor Yellow
    }
}

function Set-PowerShellProfile { # Load PowerShell Profile
    Write-host "Downloading PowerShell profile from GitHub."
}

function Enable-NumlockBoot { # Enable NumLock on Boot
    Write-host "Enabling Numlock on boot."
    Set-ItemProperty -Path 'HKU:\.DEFAULT\Control Panel\Keyboard' -Name "InitialKeyboardIndicators" -Value "2"
}

function Disable-Teredo { # Disable Teredo Tunneling protocol
    Write-Host "Disabling Teredo Tunneling protocol."
    netsh interface teredo set state disabled
}

function Disable-StartMenuRecommendations { # Disable Start Menu Recommendations
    # Check if the OS is Windows 11
    Write-host "Disabling Start Menu Recommendations."
    Write-host "Verfying Windows 11."
    $windowsBuild = [System.Environment]::OSVersion.Version.Build
    if ($windowsBuild -ge 22000) {
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Recommended" -PropertyType DWord -Value 0 -Force
        Write-host "Start Menu Recommendations disabled."
    } else {
        Write-Host "Skipping Start Menu Recommendations setting (only applies to Windows 11)." -ForegroundColor Yellow
    }
}

function Show-FileExtensions { # Show File Extensions
    Write-Host "Enabling file extensions visibility..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
}

function Disable-Homegroup { # Disable Homegroup
    Write-Host "Disabling HomeGroup services..."
    Stop-Service "HomeGroupListener" -Force -ErrorAction SilentlyContinue
    Stop-Service "HomeGroupProvider" -Force -ErrorAction SilentlyContinue
    Set-Service "HomeGroupListener" -StartupType Disabled
    Set-Service "HomeGroupProvider" -StartupType Disabled
}

function Disable-Hibernation { # Disable Hibernation
    Write-Host "Disabling hibernation..."
    powercfg.exe /hibernate off
}

function Disable-StorageSense { # Disable Storage Sense
    Write-Host "Disabling Storage Sense..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type Dword -Force
}

function Add-TaskbarEndTask { # Add "End Task" to Right-Click Menu
    Write-Host "Adding ""End Task"" to Taskbar right-click menu"
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
    $name = "TaskbarEndTask"
    $value = 1

    if ( -not ( Test-Path $path )) {
        New-Item -Path $path -Force | Out-Null
    }

    if ( -not ( Get-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue )) {
        New-ItemProperty -Path $path -Name $name -PropertyType DWord -Value $value -Force | Out-Null
    }
}

function Disable-PowerShell7Telemetry { # Disable PowerShell 7 Telemetry
    write-host "Disabling PowerShell 7 Telemetry"
    [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')
}

function Set-ServicesManual { # Set Common Services to Manual
    Write-Host "Setting certain services to manual startup."
    # Download TXT file from Github
    # Read file and loop through to set services to manual
}

function Set-DebloatEdge { # Debloat Edge
    $RegistryChanges = @(
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"; Name="CreateDesktopShortcutDefault"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="EdgeEnhanceImagesEnabled"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="PersonalizationReportingEnabled"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="ShowRecommendationsEnabled"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="HideFirstRunExperience"; Type="DWord"; Value=1}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="UserFeedbackAllowed"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="ConfigureDoNotTrack"; Type="DWord"; Value=1}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="AlternateErrorPagesEnabled"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="EdgeCollectionsEnabled"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="EdgeFollowEnabled"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="EdgeShoppingAssistantEnabled"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="MicrosoftEdgeInsiderPromotionEnabled"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="ShowMicrosoftRewards"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="WebWidgetAllowed"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="DiagnosticData"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="EdgeAssetDeliveryServiceEnabled"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="CryptoWalletEnabled"; Type="DWord"; Value=0}
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="WalletDonationEnabled"; Type="DWord"; Value=0}
    )

    foreach ( $change in $RegistryChanges ) {
        if ( -not ( Test-Path $change.Path )) {
            New-Item -Path $change.Path -Force | Out-Null
        }
        Set-ItemProperty -Path $change.Path -Name $change.Name -Type $change.Type -Value $change.Value
    }
}

function Enable-DetailedBSoD { # Enable Detailed BSoD
    Write-Host "Enabling detailed BSoD..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "DisplayParameters" -Value 1 -Force
}

function Disable-ConsumerFeatures { # Disable Consumer Features
    Write-Host "Disabling consumer features..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Force
}

function Set-PreferIPv4 { # Set IPv4 as preferred over IPv6
    Write-Host "Setting IPv4 as preferred over IPv6. This does NOT disable IPv6"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 32 -Type DWord
}