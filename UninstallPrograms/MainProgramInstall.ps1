#CLEAR CONSOLE WINDOW
clear-host
#region - DECLARATIONS
  # UNCOMMENT LINE BELOW TO DISABLE WGET PROGRESS BAR
  #$ProgressPreference = 'SilentlyContinue'
  # SET SSL/TLS
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  # Prevents Apps from re-installing
  $cdm = @(
    "ContentDeliveryAllowed",
    "FeatureManagementEnabled",
    "OemPreInstalledAppsEnabled",
    "PreInstalledAppsEnabled",
    "PreInstalledAppsEverEnabled",
    "SilentInstalledAppsEnabled",
    "SubscribedContent-314559Enabled",
    "SubscribedContent-338387Enabled",
    "SubscribedContent-338388Enabled",
    "SubscribedContent-338389Enabled",
    "SubscribedContent-338393Enabled",
    "SubscribedContentEnabled",
    "SystemPaneSuggestionsEnabled"
  )

  $apps = @(
    # default Windows 10 apps
    "TikTok",
    "DellInc.DellSupportAssisstforPcs",
    "Microsoft.3DBuilder",
    "Microsoft.Appconnector",
    "Microsoft.BingFinance",
    "Microsoft.BingNews",
    "Microsoft.BingSports",
    "Microsoft.BingTranslator",
    "Microsoft.BingWeather",
    #"Microsoft.FreshPaint",
    "Microsoft.GamingServices",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftPowerBIForWindows",
    "Microsoft.MicrosoftSolitaireCollection",
    #"Microsoft.MicrosoftStickyNotes",
    "Microsoft.MinecraftUWP",
    "Microsoft.NetworkSpeedTest",
    "Microsoft.Office.OneNote",
    #"Microsoft.OneConnect",
    "Microsoft.People",
    "Microsoft.Print3D",
    "Microsoft.SkypeApp",
    "Microsoft.Wallet",
    #"Microsoft.Windows.Photos",
    "Microsoft.WindowsAlarms",
    #"Microsoft.WindowsCalculator",
    "Microsoft.WindowsCamera",
    "microsoft.windowscommunicationsapps",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsPhone",
    "Microsoft.WindowsSoundRecorder",

    #"Microsoft.WindowsStore",   # can't be re-installed
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",

    # Threshold 2 apps
    "Microsoft.CommsPhone",
    "Microsoft.ConnectivityStore",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Messaging",
    "Microsoft.Office.Sway",
    "Microsoft.OneConnect",
    "Microsoft.WindowsFeedbackHub",

    # Creators Update apps
    "Microsoft.Microsoft3DViewer",
    #"Microsoft.MSPaint",

    #Redstone apps
    "Microsoft.BingFoodAndDrink",
    "Microsoft.BingHealthAndFitness",
    "Microsoft.BingTravel",
    "Microsoft.WindowsReadingList",

    # Redstone 5 apps
    "Microsoft.MixedReality.Portal",
    "Microsoft.ScreenSketch",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.YourPhone",

    # non-Microsoft
    "2FE3CB00.PicsArt-PhotoStudio",
    "46928bounde.EclipseManager",
    "4DF9E0F8.Netflix",
    "613EBCEA.PolarrPhotoEditorAcademicEdition",
    "6Wunderkinder.Wunderlist",
    "7EE7776C.LinkedInforWindows",
    "89006A2E.AutodeskSketchBook",
    "9E2F88E3.Twitter",
    "A278AB0D.DisneyMagicKingdoms",
    "A278AB0D.MarchofEmpires",
    "ActiproSoftwareLLC.562882FEEB491",
    "CAF9E577.Plex",
    "ClearChannelRadioDigital.iHeartRadio",
    "D52A8D61.FarmVille2CountryEscape",
    "D5EA27B7.Duolingo-LearnLanguagesforFree",
    "DB6EA5DB.CyberLinkMediaSuiteEssentials",
    "DolbyLaboratories.DolbyAccess",
    "DolbyLaboratories.DolbyAccess",
    "Drawboard.DrawboardPDF",
    "Facebook.Facebook",
    "Fitbit.FitbitCoach",
    "Flipboard.Flipboard",
    "GAMELOFTSA.Asphalt8Airborne",
    "KeeperSecurityInc.Keeper",
    "Microsoft.BingNews",
    "NORDCURRENT.COOKINGFEVER",
    "PandoraMediaInc.29680B314EFC2",
    "Playtika.CaesarsSlotsFreeCasino",
    "ShazamEntertainmentLtd.Shazam",
    "SlingTVLLC.SlingTV",
    "SpotifyAB.SpotifyMusic",
    #"TheNewYorkTimes.NYTCrossword",
    "ThumbmunkeysLtd.PhototasticCollage",
    "TuneIn.TuneInRadio",
    "WinZipComputing.WinZipUniversal",
    "XINGAG.XING",
    "flaregamesGmbH.RoyalRevolt2",
    "king.com.*",
    "king.com.BubbleWitch3Saga",
    "king.com.CandyCrushSaga",
    "king.com.CandyCrushSodaSaga",

    # apps which cannot be removed using Remove-AppxPackage
    #"Microsoft.BioEnrollment",
    #"Microsoft.MicrosoftEdge",
    #"Microsoft.Windows.Cortana",
    #"Microsoft.WindowsFeedback",
    #"Microsoft.XboxGameCallableUI",
    #"Microsoft.XboxIdentityProvider",
    #"Windows.ContactSupport",

    # apps which other apps depend on
    "Microsoft.Advertising.Xaml"
  )
#endregion

#region - FUNCTIONS
  function perform_tasks() {
    $totalTasks = 8
    $currentTask = 1
    start-sleep -seconds 1

    ### Download the 4 Programs ###
    Write-Progress -Activity "Downloading and Installing: WireGuard" -PercentComplete ($currentTask/$totalTasks*100)
    try { #  Attempt install
      wget "https://download.wireguard.com/windows-client/wireguard-amd64-0.5.3.msi" -outfile "c:\ccg\wireguard-installer.msi"
      Start-Process -FilePath "msiexec.exe" -wait -nonewwindow -ArgumentList '/i "c:\ccg\wireguard-installer.msi" /qn /norestart'
      $currentTask++
      start-sleep -seconds 1
    } catch { #  If install fails, run catch, warning user
      write-host "Failed to install WireGuard"
      write-host $_.Exception.Message
      write-host $_.scriptstacktrace
      write-host $_
    }

    Write-Progress -Activity "Downloading and Installing: Yubikey Manager" -PercentComplete ($currentTask/$totalTasks*100)
    try { #  Attempt install
      wget "https://developers.yubico.com/yubikey-manager-qt/Releases/yubikey-manager-qt-latest-win64.exe" -outfile "c:\ccg\yubikey-manager-qt-latest-win64.exe"
      Start-Process -FilePath "c:\ccg\yubikey-manager-qt-latest-win64.exe" -wait -nonewwindow -ArgumentList "/S"
      $currentTask++
      start-sleep -seconds 1
    } catch { #  If install fails, run catch, warning user
      write-host "Failed to install Yubikey Manager"
      write-host $_.Exception.Message
      write-host $_.scriptstacktrace
      write-host $_
    }
    
    Write-Progress -Activity "Downloading and Installing: Chrome" -PercentComplete ($currentTask/$totalTasks*100)
    try { #  Attempt install
      wget "http://dl.google.com/chrome/install/375.126/chrome_installer.exe" -outfile "c:\ccg\chromesetup.exe"
      Start-Process -FilePath "c:\ccg\chromesetup.exe" -wait -nonewwindow -ArgumentList "/silent /install"
      $currentTask++
      start-sleep -seconds 1
    } catch { #  If install fails, run catch, warning user
      write-host "Failed to install Chrome"
      write-host $_.Exception.Message
      write-host $_.scriptstacktrace
      write-host $_
    }
    
    Write-Progress -Activity "Downloading and Installing: Adobe Reader" -PercentComplete ($currentTask/$totalTasks*100)
    try { #  Attempt install
      wget "ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/1800920044/AcroRdrDC1800920044_en_US.exe" -outfile "c:\ccg\AcroRdrDC1800920044_en_US.exe"
      Start-Process -FilePath "c:\ccg\AcroRdrDC1800920044_en_US.exe" -wait -nonewwindow -ArgumentList "/sAll /rs /rps"
      $currentTask++
      start-sleep -seconds 1
    } catch { #  If install fails, run catch, warning user
      write-host "Failed to install Adobe Reader"
      write-host $_.Exception.Message
      write-host $_.scriptstacktrace
      write-host $_
    }

    ### Uninstall Bloatware ###
    Write-Progress -Activity "Uninstalling Common Bloatware" -PercentComplete ($currentTask/$totalTasks*100)
    try { #  Attempt uninstall
      foreach ($app in $apps) {
        try { #  Attempt uninstall
          write-host "Trying to remove: $($app)"
          Get-AppxPackage -Verbose:$false -Name $app -AllUsers | Remove-AppxPackage -AllUsers
          Get-AppXProvisionedPackage -Verbose:$false -Online | Where-Object DisplayName -eq $app | Remove-AppxProvisionedPackage -Online
        } catch { #  If uninstall fails, run catch, warning user
          write-host "`n`n`n Was not able to remove: $($app)" 
          continue
        }
      }

      $currentTask++
      start-sleep -seconds 1
    } catch { #  If uninstall fails, run catch, warning user
      write-host $_.Exception.Message
      write-host $_.scriptstacktrace
      write-host $_
    }
    
    ### KILL OEM INSTALLED OFFICE INFO ###
    if ((get-item -path "HKLM:\Software\Microsoft\Office\16.0\Common\OEM" -erroraction silentlycontinue) -or
      (get-item -path "HKLM:\Software\WOW6432Node\Microsoft\Office\16.0\Common\OEM" -erroraction silentlycontinue)) {
        Write-Progress -Activity "Removing OEM Installed Office Data" -PercentComplete ($currentTask/$totalTasks*100)
        try { #  Attempt uninstall
          if (!(test-path C:\log)){ mkdir C:\log } # this was the issue. folder wasn't created and reg export can't create the folder itself.
          reg export HKLM\Software\Microsoft\Office\16.0\Common\OEM C:\Log\OEM_Office_32.reg /y
          reg export HKLM\Software\WOW6432Node\Microsoft\Office\16.0\Common\OEM C:\Log\OEM_Office_64.reg /y
          reg delete HKLM\Software\Microsoft\Office\16.0\Common\OEM /va /f
          reg delete HKLM\Software\WOW6432Node\Microsoft\Office\16.0\Common\OEM /va /f
          $currentTask++
          start-sleep -seconds 1
        } catch { #  If uninstall fails, run catch, warning user
          write-host $_.Exception.Message
          write-host $_.scriptstacktrace
          write-host $_
        }
    } else {
      write-host "No OEM Installed Office Data"
    }

    ### Change Computer Name and Restart ###
    Write-Progress -Activity "Changing Computer Name" -PercentComplete ($currentTask/$totalTasks*100)
    try { #  Attempt uninstall
      $CN = (Get-WmiObject -class win32_bios).SerialNumber
      Rename-Computer -NewName "CCG-$CN"
      $currentTask++
      start-sleep -seconds 1
    } catch { #  If uninstall fails, run catch, warning user
      write-host $_.Exception.Message
      write-host $_.scriptstacktrace
      write-host $_
    }

    try { #  Attempt uninstall
      Write-Progress -Activity "Finishing Up" -PercentComplete ($currentTask/$totalTasks*100)
      $percentcomp=($currentTask/$totalTasks*100)
      start-sleep -seconds 1
      if ($percentcomp -ge 99) {
        #Restart-Computer
      } else {
        write-host "`n`n`nThe function either didn't finish or a command failed to run properly.`n`n`n"
      }
    } catch { #  If uninstall fails, run catch, warning user
      write-host "`n`n`nThere was an error somewhere in the function.`n`n`n"
    }
  }
#endregion - FUNCTIONS


#BEGIN SCRIPT
#GRAB CURRENT EXECUTION POLICY
$policy = get-executionpolicy
#SET EXECUTIONPOLICY BYPASS
set-executionpolicy bypass
#SET PSGALLERY AS A TRUSTED SOURCE
#Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
#INSTALL NUGET PROVIDER
if (-not (Get-PackageProvider -name NuGet)) {
  Install-PackageProvider -Name NuGet -Force <#-Confirm:$false#>; Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
}
#GET PSWINDOWSUPDATE MODULE IF NOT INSTALLED
if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
  try { #  Attempt uninstall
    Import-Module PSWindowsUpdate
  } catch { #  If uninstall fails, run catch, warning user
    write-host $_.Exception.Message
    write-host $_.scriptstacktrace
    write-host $_
  }
} else {
  try { #  Attempt uninstall
    Install-Module PSWindowsUpdate -Force -Confirm:$false
    Import-Module PSWindowsUpdate
  } catch { #  If uninstall fails, run catch, warning user
    write-host $_.Exception.Message
    write-host $_.scriptstacktrace
    write-host $_
  }
}
#SET PSGALLERY BACK AS AN UNTRUSTED SOURCE
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Untrusted

try { #  Attempt uninstall
  try { #  Attempt uninstall
    mkdir -Verbose:$false c:/ccg/ -ErrorAction SilentlyContinue
    cd c:/ccg -ErrorAction SilentlyContinue
  } catch { #  If uninstall fails, run catch, warning user
    write-host $_.Exception.Message
    write-host $_.scriptstacktrace
    write-host $_
  }

  try { #  Attempt uninstall
    #CALL FUNCTION TO DO EVERYTHING
    perform_tasks
  } catch { #  If uninstall fails, run catch, warning user
    Write-Host "`n`n`nThe function failed to run properly."
    write-host $_.Exception.Message
    write-host $_.scriptstacktrace
    write-host $_
  }
} catch { #  If uninstall fails, run catch, warning user
  write-host $_.Exception.Message
  write-host $_.scriptstacktrace
  write-host $_
}
#REVERT EXECUTIONPOLICY TO ORIGINAL SCOPE
set-executionpolicy $policy
#END SCRIPT