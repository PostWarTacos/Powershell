#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Filename: UninstallPrograms
#  Intent: Uninstall specified programs
#  Author: Matthew Wurtz
#  Date: 4/8/20223
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#  Installed AppX Packages
$AppXPackages = @(
    "Microsoft.Office.Desktop",
    "Microsoft.Office.OneNote”,
    "DellInc.DellDigitalDelivery"
)

#  Installed Programs
$InstalledPrograms = @(
    "MyDell",
    "MyDell Application Management",
    "MyDell Components Installer",
    "MyDell Customer Connect",
    "WebAdvisor by McAfee",
    "Dell Optimizer Service",
    "McAfee Small Business - PC Security",
    "Dell Digital Delivery Services",
    "Microsoft OneNote - en-us",
    "Microsoft 365 - en-us"

)

#  Running Procs/Servs
$KillProcess = @(
    "MyDell",
    "Office",
    "McAfee"
)

$AppCount = $AppXPackages.Count + $InstalledPrograms.Count
$i = 0

#  Kill running procs
foreach ($Proc in $KillProcess){
    Get-Process | ? {$_.Name -like "*$Proc*"} | Stop-Process -Force -ErrorAction SilentlyContinue
}

#  Kill running servs
foreach ($Serv in $KillProcess){
    Get-Service | ? {$_.Name -like "*$Serv*"} | Stop-Service -Force -ErrorAction SilentlyContinue
}

#  Remove appx packages
ForEach ($AppX in $AppXPackages) {
                                            
    Write-Host -Object "Attempting to remove Appx package: [$AppX]..."

    Try {
        $Null = Get-AppxPackage -Name *$Appx* | Remove-AppxPackage -AllUsers -ErrorAction Stop
        Write-Host -Object "Successfully removed Appx package: [$AppX]"
    }
    Catch {Write-Warning -Message "Failed to remove Appx package: [$AppX]"}

#  Progress bar
    $i += 1
    $progress = (($i / $AppCount)*100).tostring("##.##")
    Write-Progress -Activity "Uninstalling Programs..." -Status $progress% -PercentComplete $progress
}

#  Remove installed programs
Foreach ($Program in $InstalledPrograms) {

    Write-Host -Object "Attempting to uninstall: [$Program]..."

    Try {
        $Null = Get-package -name *$Program* | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        Write-Host -Object "Successfully uninstalled: [$Program]"
    }
    Catch {Write-Warning -Message "Failed to uninstall: [$Program]"}

#  Progress bar
    $i += 1
    $progress = (($i / $AppCount)*100).tostring("##.##")
    Write-Progress -Activity "Uninstalling Programs..." -Status $progress% -PercentComplete $progress
}


<#
#  Reboot Required?
$input = Read-Host "Restart computer now [y/n]"
switch($input){
          y{Restart-computer -Force -Confirm:$false}
          n{exit}
    default{write-warning "Skipping reboot."}
}
#>