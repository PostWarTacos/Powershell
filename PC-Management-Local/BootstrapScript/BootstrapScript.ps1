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

function Install-NvidiaApp { # Download and install Nvidia App. Not available in winget.    #~~# WORKS IN WIN11 #~~#
    Write-Output "Downloading and installing Nvidia App."
    $downloadURL = "https://www.nvidia.com/en-us/software/nvidia-app/"
    $downloadPage = Invoke-WebRequest -Uri $downloadURL -UseBasicParsing
    $installerURL = $downloadPage.Links | Where-Object { $_.href -match "Nvidia_App_v\d+(\.\d+)*.exe" } | Select-Object -First 1 -ExpandProperty href
    
    if ($installerURL) { # Only download and install if valid URL found
        $installerPath = "$env:TEMP\NvidiaApp.exe"
        Invoke-WebRequest -Uri $installerURL -OutFile $installerPath
        If (Test-Path $installerPath){ # Verify downloaded
            Start-Process -FilePath $installerPath -ArgumentList "/s" -Wait
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
        Start-Process -FilePath $installerPath -ArgumentList "/s" -Wait
    }

    $overwolf = reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s | findstr /I "Overwolf"
    If($overwolf){ # Verify installed
        Write-Output "Overwolf installed successfully."
    } else {
        Write-Output "Failed to retrieve the latest Overwolf installer."
    } 
}

function Install-RuckZuck { # Download and install RuckZuck. Not available in winget   #~~# WORKS IN WIN11 #~~#
    Write-Output "Downloading and installing RuckZuck."
    $downloadURL = "https://github.com/rzander/ruckzuck/releases/download/1.7.3.8/RuckZuck.exe"
    $installerPath = "C:\Program Files (x86)\RuckZuck"
    #$installerURL = $downloadPage.Links | Where-Object { $_.href -match "RuckZuck.exe" } | Select-Object -First 1 -ExpandProperty href
    
    if ($downloadURL) { # Only download and install if valid URL found
        If( -not ( Test-Path $installerPath )){
            mkdir $installerPath
        }
        Invoke-WebRequest -Uri $downloadURL -OutFile "$installerPath\RuckZuck.exe"
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
Turn on/off Recommendations in start menu    (Not working)
Pointer size 3 or 4    (modify to depend on resolution)
Zoom and font size    (modify to depend on resolution)
Green cursor
Short Date (dd-MMM-yy)
24-hour Short Time
24-hour Long Time w/seconds
PowerShell Profile
Numlock on boot
Show file extensions
Add "End Task" to right click
Set IPv4 as preferred
Debloat Edge
Detailed BSoD
Disable PowerShell 7 Telemetry
Disable Teredo tunneling protocol
Disable hibernation
Disable storage sense
Disable consumer features    (Not working)
Disable and remove OneDrive
Disable and remove Copilot
Disable and remove Recall app/services
#>

<# IN DEV SETTING CHANGES
Disable Telemetry
Set certain services to manual
Add shortcuts to taskbar and start menu
Separate ADM account
Reset background based on photo saved to Git
Zoom and font size
Remove popups on lockscreen
Modify lockscreen widget
#>

function Set-PowerShellProfile { # Load PowerShell Profile
    Write-Output "Downloading PowerShell profile from GitHub."
}

# Function to open Mouse Pointer Settings UI and set the color & size
function Set-MousePointer {   #~~# WORKS IN WIN11 #~~#
    Write-Output "Setting mouse pointer color and size."
    Start-Process "ms-settings:easeofaccess-mousepointer"  # Open Ease of Access Mouse Settings
    Start-Sleep -Seconds 2  # Wait for settings window to open

    # Send keystrokes to navigate the UI (Requires UIAutomation for full automation)
    Add-Type -AssemblyName System.Windows.Forms

    # Move to Color Picker and set custom lime color
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}{TAB}{TAB}{TAB}{HOME}{RIGHT}{RIGHT}{RIGHT}{ENTER}")  # Opens color selection
    Start-Sleep -Seconds 1
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}{HOME}{RIGHT}{ENTER}")  # Selects Lime Green

    # Move to Size slider and adjust
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}{TAB}{HOME}{RIGHT}{RIGHT}{RIGHT}{ENTER}")  # Moves to size and increases
    Start-Sleep -Seconds 1

    # Close the settings window
    Start-Sleep -Seconds 1
    [System.Windows.Forms.SendKeys]::SendWait("%{F4}")  # Alt+F4 to close
}

function Set-MilDateTimeFormat{ # Mil Date and Time Format  #~~# WORKS IN WIN11 #~~#
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

function Disable-Recall { # Disable Recall App/Services (For Windows 11 with Recall)    #~~# APPEARS TO WORK IN WIN11. NEED VERIFY SCRIPT. #~~#
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

function Enable-NumlockBoot { # Enable NumLock on Boot  #~~# WORKS IN WIN11 #~~#
    Write-Output "Enabling Numlock on boot."
    Set-ItemProperty -Path 'HKCU:\Control Panel\Keyboard' -Name "InitialKeyboardIndicators" -Value "2"
}

function Disable-Teredo { # Disable Teredo Tunneling protocol  #~~# WORKS IN WIN11 #~~#
    Write-Output "Disabling Teredo Tunneling protocol."
    netsh interface teredo set state disabled
}

function Show-FileExtensions { # Show File Extensions   #~~# WORKS IN WIN11 #~~#
    Write-Output "Enabling file extensions visibility..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
}

function Disable-Hibernation { # Disable Hibernation  #~~# WORKS IN WIN11 #~~#
    Write-Output "Disabling hibernation..."
    powercfg.exe /hibernate off
}

function Disable-StorageSense { # Disable Storage Sense  #~~# WORKS IN WIN11 #~~#
    Write-Output "Disabling Storage Sense..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type Dword -Force
}

function Add-TaskbarEndTask { # Add "End Task" to Right-Click Menu   #~~# WORKS IN WIN11 #~~#
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

function Disable-PowerShell7Telemetry { # Disable PowerShell 7 Telemetry  #~~# WORKS IN WIN11 #~~#
    Write-Output "Disabling PowerShell 7 Telemetry"
    [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')
}

function Set-ServicesManual { # Set Common Services to Manual
    Write-Output "Setting certain services to manual startup."
    # Download TXT file from Github
    # Read file and loop through to set services to manual
}

function Set-DebloatEdge { # Debloat Edge   #~~# WORKS IN WIN11 #~~#
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

function Enable-DetailedBSoD { # Enable Detailed BSoD  #~~# WORKS IN WIN11 #~~#
    Write-Output "Enabling detailed BSoD..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "DisplayParameters" -Value 1 -Force
}

function Set-PreferIPv4 { # Set IPv4 as preferred over IPv6   #~~# WORKS IN WIN11 #~~#
    Write-Output "Setting IPv4 as preferred over IPv6. This does NOT disable IPv6"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 32 -Type DWord
}

function Uninstall-OneDrive{
    $OneDrivePath = $($env:OneDrive)
    Write-Host "Removing OneDrive"
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe"
    if (Test-Path $regPath) {
        $OneDriveUninstallString = Get-ItemPropertyValue "$regPath" -Name "UninstallString"
        $OneDriveExe, $OneDriveArgs = $OneDriveUninstallString.Split(" ")
        Start-Process -FilePath $OneDriveExe -ArgumentList "$OneDriveArgs /silent" -NoNewWindow -Wait
    } else {
        Write-Host "Onedrive dosn't seem to be installed anymore" -ForegroundColor Red
        return
    }
    # Check if OneDrive got Uninstalled
    if (-not (Test-Path $regPath)) {
        Write-Host "Copy downloaded Files from the OneDrive Folder to Root UserProfile"
        Start-Process -FilePath powershell -ArgumentList "robocopy '$($OneDrivePath)' '$($env:USERPROFILE.TrimEnd())\' /mov /e /xj" -NoNewWindow -Wait

        Write-Host "Removing OneDrive leftovers"
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:localappdata\Microsoft\OneDrive"
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:localappdata\OneDrive"
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:programdata\Microsoft OneDrive"
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:systemdrive\OneDriveTemp"
        Remove-Item -Path "HKCU:\Software\Microsoft\OneDrive" -Recurse -Force
        # check if directory is empty before removing:
        If ((Get-ChildItem "$OneDrivePath" -Recurse | Measure-Object).Count -eq 0) {
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$OneDrivePath"
        }

        Write-Host "Remove Onedrive from explorer sidebar"
        # Define the fully qualified paths for the registry keys
        $clsidPathHKCR = "Registry::HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
        $clsidPathWow6432 = "Registry::HKEY_LOCAL_MACHINE\Software\Classes\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"

        # Check and modify the HKCR key if it exists
        if (Test-Path $clsidPathHKCR) {
            Set-ItemProperty -Path $clsidPathHKCR -Name "System.IsPinnedToNameSpaceTree" -Value 0
            Write-Host "Updated System.IsPinnedToNameSpaceTree for HKCR CLSID."
        } else {
            Write-Host "The key $clsidPathHKCR does not exist."
        }

        # Check and modify the Wow6432Node key if it exists
        if (Test-Path $clsidPathWow6432) {
            Set-ItemProperty -Path $clsidPathWow6432 -Name "System.IsPinnedToNameSpaceTree" -Value 0
            Write-Host "Updated System.IsPinnedToNameSpaceTree for Wow6432Node CLSID."
        } else {
            Write-Host "The key $clsidPathWow6432 does not exist."
        }
        
        Write-Host "Removing run hook for new users"
        reg load "hku\Default" "C:\Users\Default\NTUSER.DAT"
        $regPath = "Registry::HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        Remove-ItemProperty -Path $regPath -Name "OneDriveSetup" -ErrorAction SilentlyContinue
        reg unload "hku\Default"

        Write-Host "Removing startmenu entry"
        Remove-Item -Force -ErrorAction SilentlyContinue "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"

        Write-Host "Removing scheduled task"
        Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ea SilentlyContinue | Unregister-ScheduledTask -Confirm:$false

        # Add Shell folders restoring default locations
        Write-Host "Shell Fixing"
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "AppData" -Value "$env:userprofile\AppData\Roaming" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Cache" -Value "$env:userprofile\AppData\Local\Microsoft\Windows\INetCache" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Cookies" -Value "$env:userprofile\AppData\Local\Microsoft\Windows\INetCookies" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Favorites" -Value "$env:userprofile\Favorites" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "History" -Value "$env:userprofile\AppData\Local\Microsoft\Windows\History" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Local AppData" -Value "$env:userprofile\AppData\Local" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "My Music" -Value "$env:userprofile\Music" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "My Video" -Value "$env:userprofile\Videos" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "NetHood" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Network Shortcuts" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "PrintHood" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Printer Shortcuts" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Programs" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Recent" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Recent" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "SendTo" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\SendTo" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Start Menu" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Startup" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Templates" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Templates" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}" -Value "$env:userprofile\Downloads" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Desktop" -Value "$env:userprofile\Desktop" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "My Pictures" -Value "$env:userprofile\Pictures" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Personal" -Value "$env:userprofile\Documents" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{F42EE2D3-909F-4907-8871-4C22FC0BF756}" -Value "$env:userprofile\Documents" -Type ExpandString
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{0DDD015D-B06C-45D5-8C4C-F59713854639}" -Value "$env:userprofile\Pictures" -Type ExpandString
        Write-Host "Restarting explorer"
        taskkill.exe /F /IM "explorer.exe"
        Start-Process "explorer.exe"

        Write-Host "Waiting for explorer to complete loading"
        Write-Host "Please Note - The OneDrive folder at $OneDrivePath may still have items in it. You must manually delete it, but all the files should already be copied to the base user folder."
        Write-Host "If there are Files missing afterwards, please Login to Onedrive.com and Download them manually" -ForegroundColor Yellow
        Start-Sleep 5
    } else {
        Write-Host "Something went Wrong during the Unistallation of OneDrive" -ForegroundColor Red
    }
}

function Disable-Copilot{
    # Remove the Windows Copilot package using DISM
    Write-Host "Removing Windows Copilot package..."
    try {
        # Remove the Copilot package for the current user (or all users if applicable)
        Write-Host "Searching for the Windows Copilot package..."
        $app = Get-AppxPackage -Name "*Copilot*"
        if ($app) {
            Write-Host "Found Copilot package. Removing it..."
            # Remove for all users
            $app | Remove-AppxPackage -AllUsers
            Write-Host "Copilot package removed successfully."
        } else {
            Write-Host "No installed Copilot package found."
        }

        # Optionally, remove the provisioned package so new user profiles don't get it installed
        Write-Host "Checking for provisioned Copilot package..."
        $appProv = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*Copilot*" }
        if ($appProv) {
            Write-Host "Found a provisioned Copilot package. Removing it from the system image..."
            $appProv | Remove-AppxProvisionedPackage -Online
            Write-Host "Provisioned Copilot package removed successfully."
        } else {
            Write-Host "No provisioned Copilot package found."
        }
        Write-Host "Windows Copilot package removed successfully."
    } catch {
        Write-Error "Failed to remove Windows Copilot package. It might not be installed or an error occurred."
    }

    # Disable Copilot via registry to prevent any residual functionality
    Write-Host "Disabling Windows Copilot via registry settings..."
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    # Setting AllowCopilot to 0 disables Copilot
    New-ItemProperty -Path $regPath -Name "AllowCopilot" -Value 0 -PropertyType DWord -Force

    Write-Host "Windows Copilot has been disabled. A system reboot might be required for all changes to take effect."
}

#
# NOT WORKING IN WIN11
#

<# NOT WORKING IN WIN11
function Disable-ConsumerFeatures { # Disable Consumer Features
    Write-Output "Disabling consumer features..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Force
}
#>

<# NOT WORKING IN WIN11
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
#>

