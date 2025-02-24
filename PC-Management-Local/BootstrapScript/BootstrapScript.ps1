<# Matt's Apps to Install at Home
7Zip.7Zip
Brave.Brave
Discord.Discord
EpicGames.EpicGamesLauncher
Gimp.Gimp
GOG.Galaxy
Insecure.Nmap
Mozilla.Thunderbird
Oracle.VirtualBox
PrivateInternetAccess.PrivateInternetAccess
RevoUninstaller.RevoUninstaller
SteelSeries.GG
Valve.Steam
Overwolf    (separate install)
CurseForge    (separate install)
AlecaFrame    (separate install)
NvidiaApp    (separate install)
Global Protect      (install script in ChatGPT)
Canon Printer Drivers   (gonna be super complex)
KDAN PDF Reader / Liquid Text Editor    (decide which one)
#>

<# Matt's Apps to Install at Home & Work
AgileBits.1Password
Corsair.iCUE.5
Git.Git
JanDeDobbeleer.OhMyPosh
Microsoft.WindowsTerminal
Notion.Notion
Spotify.Spotify
VSCodium.VSCodium
WinFetch
Manually install DoD Certs        (https://militarycac.com/windows8.htm#Windows_RT)
RuckZuck    (separate install)
Devolutions.RemoteDesktopManager    (work only)
#>

<# Other Apps to List
Ubisoft.Connect
ElectronicArts.EADesktop
WiresharkFoundation.Wireshark
Zoom.Zoom
Microsoft.Teams
ms office 2021      (https://msgang.com/how-to-download-and-install-office-2021-on-windows-10/)
#>

function Install { # Universal winget function
    param (
        [string]$id  # Define the app to install
    )
    
    Write-Output "Downloading and installing $($id.split('.')[1])."
    winget install --id=$id  -e

    $found = winget list --id=$id 2>$null | Select-String "$id"
    If ([bool]$found){ # Returns $true if found, $false if not
        Write-Output "$($id.split('.')[1]) installed successfully."
    }
}

function Install-Winfetch { # Download and install WinFetch. Not available in winget
    Install-Script winfetch
}

function Install-DoDCerts { # Download and install DoD Certs.
    # === NOTE1 ===
    # If you encounter the error "There is a problem with this website's security certificate."
    # you have two options:
    # 1. Manually resolve the certificate issue per your guide.
    # 2. Bypass certificate validation for downloads (uncomment the following line).
    #
    # WARNING: Bypassing certificate validation reduces security.
    # [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

    # Define URLs for the certificate files using your provided links.
    $allCertsUrl = "https://militarycac.com/maccerts/AllCerts.p7b"
    $doDRootUrl = "https://militarycac.com/CACDrivers/DoDRoot3-6.p7b"

    # Define the Desktop path and target file names.
    $allCertsFile = "{0}\AllCerts.p7b" -f [System.Environment]::GetFolderPath("Desktop")
    $doDRootFile = "{0}\DoDRoot3-6.p7b" -f [System.Environment]::GetFolderPath("Desktop")

    # Download AllCerts.p7b.
    Write-Output "Downloading AllCerts.p7b..."
    try {
        Invoke-WebRequest -Uri $allCertsUrl -OutFile $allCertsFile -UseBasicParsing
        Write-Output "Downloaded AllCerts.p7b to $allCertsFile"
    }
    catch {
        Write-Error "Failed to download AllCerts.p7b: $_"
        Write-Output "If you see a certificate error, please refer to your certificate troubleshooting guide (NOTE1)."
        exit
    }

    # Install AllCerts.p7b into the Intermediate Certification Authorities store (store name: CA).
    Write-Output "Installing AllCerts.p7b into Intermediate Certification Authorities..."
    try {
        certutil -addstore "CA" $allCertsFile
        Write-Output "Successfully installed AllCerts.p7b"
    }
    catch {
        Write-Error "Failed to install AllCerts.p7b: $_"
    }

    # Clean up downloaded AllCerts.p7b file
    Write-Output "Cleaning up downloaded AllCerts.p7b file..."
    try {
        Remove-Item -Path $allCertsFile -Force
        Write-Output "Downloaded AllCerts.p7b file deleted."
    }
    catch {
        Write-Error "Failed to delete AllCerts.p7b file: $_"
    }

    # Download DoDRoot3-6.p7b.
    Write-Output "Downloading DoDRoot3-6.p7b..."
    try {
        Invoke-WebRequest -Uri $doDRootUrl -OutFile $doDRootFile -UseBasicParsing
        Write-Output "Downloaded DoDRoot3-6.p7b to $doDRootFile"
    }
    catch {
        Write-Error "Failed to download DoDRoot3-6.p7b: $_"
        Write-Output "If you see a certificate error, please refer to your certificate troubleshooting guide (NOTE1)."
        exit
    }

    # Install DoDRoot3-6.p7b into the Trusted Root Certification Authorities store (store name: ROOT).
    Write-Output "Installing DoDRoot3-6.p7b into Trusted Root Certification Authorities..."
    try {
        certutil -addstore "ROOT" $doDRootFile -f
        Write-Output "Successfully installed DoDRoot3-6.p7b"
    }
    catch {
        Write-Error "Failed to install DoDRoot3-6.p7b: $_"
    }

    # Clean up downloaded DoDRoot3-6.p7b file
    Write-Output "Cleaning up downloaded DoDRoot3-6.p7b file..."
    try {
        Remove-Item -Path $doDRootFile -Force
        Write-Output "Downloaded DoDRoot3-6.p7b file deleted."
    }
    catch {
        Write-Error "Failed to delete DoDRoot3-6.p7b file: $_"
    }

    # === NOTE2 ===
    # Since the Cross Cert Removal Tool is only written for regular Windows,
    # if you need to clear the certificates later, please follow your manual clearance guide.
    # For example, to remove a certificate manually, you could use:
    #   Remove-Item -Path Cert:\LocalMachine\ROOT\<CertificateThumbprint>
    # Make sure to verify certificate details before removal.

    Write-Output "Certificate installation complete."
    Write-Output "Reminder: If you need to clear installed certificates manually, follow your manual clearance guide (NOTE2)."

}

function Install-NvidiaApp { # Download and install Nvidia App. Not available in winget
    Write-Output "Downloading and installing Nvidia App."
    $downloadURL = "https://www.nvidia.com/en-us/software/nvidia-app/"
    $downloadPage = Invoke-WebRequest -Uri $downloadURL -UseBasicParsing
    $installerURL = $downloadPage.Links | Where-Object { $_.href -match "Nvidia_App_v\d+(\.\d+)*.exe" } | Select-Object -First 1 -ExpandProperty href
    
    if ($installerURL) { # Only download and install if valid URL found
        $installerPath = "$env:TEMP\NvidiaApp.exe"
        Invoke-WebRequest -Uri $installerURL -OutFile $installerPath
        If (Test-Path $installerPath){ # Verify downloaded
            Start-Process -FilePath $installerPath -ArgumentList "/silent" -Wait
        }
    }

    $nvidiaApp = Get-AppxPackage -Name NVIDIACorp.NVIDIAControlPanel
    If($nvidiaApp){ # Verify installed
        Write-Output "Nvidia App installed successfully."
    } else {
        Write-Output "Failed to retrieve the latest Nvidia App installer."
    }    
}

function Install-Overwolf { # Download and install Overwolf. Not available in winget
    Write-Output "Downloading and installing Overwolf."
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

function Install-RuckZuck { # Download and install RuckZuck. Not available in winget
    Write-Output "Downloading and installing RuckZuck."
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
        
        $wScriptShell = New-Object -ComObject WScript.Shell
        $shortcut = $wScriptShell.CreateShortcut($shortcutPath)
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
SetIPv4 as preferred
Disable homegroup
Debloat Edge
Disable Recall
#>

<# IN DEV SETTING CHANGES
Disable Telemetry
Completely Remove and Disable OneDrive
Set certain services to manual
Add shortcuts to taskbar and start menu
#>

# Function to open Mouse Pointer Settings UI and set the color & size
function Set-Win10Mouse { # Windows 10
    Write-Output "Setting mouse pointer color and size."
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
    Write-Output "Setting mouse pointer color and size."
}

function Set-MilDateTimeFormat{ # Mil Date and Time Format
    # Set Short Date Format
    Write-Output "Setting short date format to dd-MMM-yy."
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sShortDate" -Value "dd-MMM-yy"
    
    # Set Short Time Format - 24 clock
    Write-Output "Setting short time to 24 hour clock."
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sShortTime" -Value "HH:mm"
    
    # Set Long Time Format - 24 clock with seconds    
    Write-Output "Setting long time to 24 hour clock with seconds."
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sLongTime" -Value "HH:mm:ss"
}

function Disable-Recall { # Disable Recall App/Services (For Windows 11 with Recall)
    Write-Output "Disabling Recall."
    
    # Step 1: Disable Recall via Registry Settings
    $userRegPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI"
    $systemRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"

    New-Item -Path $userRegPath -Force | Out-Null
    Set-ItemProperty -Path $userRegPath -Name "DisableAIDataAnalysis" -Value 1 -Force

    New-Item -Path $systemRegPath -Force | Out-Null
    Set-ItemProperty -Path $systemRegPath -Name "DisableAIDataAnalysis" -Value 1 -Force

    Write-Output "Recall has been disabled via registry settings."

    # Step 2: Stop and Disable Recall Services
    $recallServices = @( "RecallSvc", "RecallIndexerSvc" )

    foreach ( $service in $recallServices ) {
        if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Output "Service '$service' has been stopped and disabled."
        } else {
            Write-Output "Service '$service' not found."
        }
    }

    # Step 3: Use DISM to Remove Recall Feature
    Start-Process -NoNewWindow -Wait -FilePath "cmd.exe" -ArgumentList "/c DISM /Online /Disable-Feature /FeatureName:Recall /Quiet /NoRestart"
}

function Set-PowerShellProfile { # Load PowerShell Profile
    Write-Output "Downloading PowerShell profile from GitHub."
}

function Enable-NumlockBoot { # Enable NumLock on Boot
    Write-Output "Enabling Numlock on boot."
    Set-ItemProperty -Path 'HKU:\.DEFAULT\Control Panel\Keyboard' -Name "InitialKeyboardIndicators" -Value "2"
}

function Disable-Teredo { # Disable Teredo Tunneling protocol
    Write-Output "Disabling Teredo Tunneling protocol."
    netsh interface teredo set state disabled
}

function Disable-StartMenuRecommendations { # Disable Start Menu Recommendations
    # Check if the OS is Windows 11
    Write-Output "Disabling Start Menu Recommendations."
    Write-Output "Verfying Windows 11."
    $windowsBuild = [System.Environment]::OSVersion.Version.Build
    if ($windowsBuild -ge 22000) {
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Recommended" -PropertyType DWord -Value 0 -Force
        Write-Output "Start Menu Recommendations disabled."
    } else {
        Write-Output "Skipping Start Menu Recommendations setting (only applies to Windows 11)." -ForegroundColor Yellow
    }
}

function Show-FileExtensions { # Show File Extensions
    Write-Output "Enabling file extensions visibility..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
}

function Disable-Homegroup { # Disable Homegroup
    Write-Output "Disabling HomeGroup services..."
    Stop-Service "HomeGroupListener" -Force -ErrorAction SilentlyContinue
    Stop-Service "HomeGroupProvider" -Force -ErrorAction SilentlyContinue
    Set-Service "HomeGroupListener" -StartupType Disabled
    Set-Service "HomeGroupProvider" -StartupType Disabled
}

function Disable-Hibernation { # Disable Hibernation
    Write-Output "Disabling hibernation..."
    powercfg.exe /hibernate off
}

function Disable-StorageSense { # Disable Storage Sense
    Write-Output "Disabling Storage Sense..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type Dword -Force
}

function Add-TaskbarEndTask { # Add "End Task" to Right-Click Menu
    Write-Output "Adding ""End Task"" to Taskbar right-click menu"
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
    Write-Output "Disabling PowerShell 7 Telemetry"
    [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')
}

function Set-ServicesManual { # Set Common Services to Manual
    Write-Output "Setting certain services to manual startup."
    # Download TXT file from Github
    # Read file and loop through to set services to manual
}

function Set-DebloatEdge { # Debloat Edge
    $regChanges = @(
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

    foreach ( $change in $regChanges ) {
        if ( -not ( Test-Path $change.Path )) {
            New-Item -Path $change.Path -Force | Out-Null
        }
        Set-ItemProperty -Path $change.Path -Name $change.Name -Type $change.Type -Value $change.Value
    }
}

function Enable-DetailedBSoD { # Enable Detailed BSoD
    Write-Output "Enabling detailed BSoD..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "DisplayParameters" -Value 1 -Force
}

function Disable-ConsumerFeatures { # Disable Consumer Features
    Write-Output "Disabling consumer features..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Force
}

function Set-PreferIPv4 { # Set IPv4 as preferred over IPv6
    Write-Output "Setting IPv4 as preferred over IPv6. This does NOT disable IPv6"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 32 -Type DWord
}