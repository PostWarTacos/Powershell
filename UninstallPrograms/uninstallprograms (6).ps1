#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Filename: Uninstallprgrams.ps1
#  Intent: Kill services and processes of list of programs and uninstall those programs. Then verify each program has been removed and produce a report.
#    The prgrams uninstalled here required  particular commands for them to be removed. As such, each program is treated a little differently below.
#  Author: Matthew Wurtz
#  Date: 23 Apr 23
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


<# ~~ Instructions to run program using PS console, rather than ISE ~~

Make sure this PS1 file is on the computer or a connected USB device.

Open PowerShell console as an admin.

Navigate to this PS1 file in the PS console running as an admin.

To navigate there, use the cd (change directory) command. Ex: cd C:\users\admin\desktop

cd only works with folders, you can't cd to .ps1. Easiest way to accomplish this is by putting in the full path to the parent directory of this script.

Once in the directory that contains this PS1 file, you can run it by just typing .\ followed by the filename and extension and hitting enter. Ex: .\uninstall.ps1

#>


#  List of services and processes to find and kill
$KillProcess = @(
    "DellOptimizer"
    "OneDrive"
    #"XBOX"
    "McAfee"
    "Dell Digital Delivery Services"
    "Dell.D3.WinSvc.exe"
    "NGA.Systray.exe"
    "NGA.Manager.exe"
    "NGA.ThickClient.exe"
)

#  Reset variables to zero to ensure no conflicts
$progress = 0
$i = 0

#  Kill running services from list
foreach ($Serv in $KillProcess){
    Get-Service | ? {$_.Name -like "*$Serv*"} | Stop-Service -Force -ErrorAction SilentlyContinue
}

#  Kill running processes from list
foreach ($Proc in $KillProcess){
    Get-Process | ? {$_.Name -like "*$Proc*"} | Stop-Process -Force -ErrorAction SilentlyContinue
}

#  List of programs to iterate through. This is solution to put all these uninstall calls in the same loop which allows us to have just one progress bar.
$ProgramList = @(
    "Dell Optimizer"    
    "MyDell"
    "OneNote"
    "365"
    "OneDrive"
    #"XBOX"
    "Dell Digital Delivery Services"
    "WebAdvisor"
)

foreach ($Program in $ProgramList){
#
#  Uninstall Dell Optimizer
#
    if ($Program -eq "Dell Optimizer"){
        #  Check registry for program
        $OptimizerString = get-itemproperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' | ? { $_.DisplayName -like "*$Program*"} -ErrorAction SilentlyContinue
        If ($OptimizerString){ #  If found, attempt uninstall
            Try { #  Attempt uninstall
                $Null = cmd /c $OptimizerString.uninstallstring -silent
                #  Verify uninstall
                if (!(get-package "*$program*")){Write-Host -Object "Successfully uninstalled: [$Program]"}
                #  If uninstall failed, warn user
                Else {Write-Warning -Message "Failed to uninstall: [$Program]"}
            }
            Catch {Write-Warning -Message "Failed to uninstall: [$Program]"} #  If uninstall fails, run catch, warning user
        }
        else{Write-Host "[$Program] was not installed"} #  Notify user that program is not installed
    }
#
#  Uninstall MyDell
#
    elseif($Program -eq "MyDell"){
        #  Check registry for program
        $MyDellString = get-itemproperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' | ? { $_.DisplayName -like "*$Program*"} -ErrorAction SilentlyContinue
        If ($MyDellString){ #  If found, attempt uninstall
            Try { #  Attempt uninstall
                $Null = cmd /c $MyDellString.uninstallstring -silent
                #  Verify uninstall
                if (!(get-package "*$program*")){Write-Host -Object "Successfully uninstalled: [$Program]"}
                #  If uninstall failed, warn user
                Else {Write-Warning -Message "Failed to uninstall: [$Program]"}
            }
            Catch {Write-Warning -Message "Failed to uninstall: [$Program]"} #  If uninstall fails, run catch, warning user
        }
        else{Write-Host "[$Program] was not installed"} #  Notify user that program is not installed
    }
#
#  Uninstall OneNote
#    
    elseif($Program -eq "OneNote"){
        #  Check registry for program
        $OneNoteString = get-itemproperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' | ? { $_.displayName -like "*$Program*"} -ErrorAction SilentlyContinue
        If ($OneNoteString){ #  If found, attempt uninstall
            Try { #  Attempt uninstall
                ForEach ($UninstallString in $OneNoteString) {
                    $UninstallEXE = ($UninstallString -split '"')[1]
                    $UninstallArg = (($UninstallString -split '"')[2] -split ";")[0] + " forceappshutdown=true DisplayLevel=False"
                    # The two lines above are the same command as the command on the next line. However, PS wasn't reading the command correctly.
                    #  Testing --- $UninstallArg = "scenario=install scenariosubtype=ARP sourcetype=None productstoremove=OneNoteFreeRetail.16_en-us_x-none culture=en-us version.16=16.0 forceappshutdown=true DisplayLevel=False"
                    Start-Process -FilePath $UninstallEXE -ArgumentList $UninstallArg -Wait
                    #  Verify uninstall
                    if (!(get-package "*$program*")){Write-Host -Object "Successfully uninstalled: [$Program]"}
                    #  If uninstall failed, warn user
                    Else {Write-Warning -Message "Failed to uninstall: [$Program]"}
                }
            }
            Catch {Write-Warning -Message "Failed to uninstall: [$Program]"} #  If uninstall fails, run catch, warning user
        }
        else{Write-Host "[$Program] was not installed"} #  Notify user that program is not installed
    }
#
#  Uninstall MS Office 365
#
    elseif($Program -eq "365"){
        #  Check registry for program
        $365String = get-itemproperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' | ? { $_.DisplayName -like "*$Program*"} -ErrorAction SilentlyContinue
        If ($365String){ #  If found, attempt uninstall
            Try { #  Attempt uninstall
                ForEach ($UninstallString in $365String) {
                    $UninstallEXE = ($UninstallString -split '"')[1]
                    $UninstallArg = (($UninstallString -split '"')[2] -split ";")[0] + " forceappshutdown=true DisplayLevel=False"
                    # The two lines above are the same command as the command on the next line. However, PS wasn't reading the command correctly.
                    #  Testing --- $UninstallArg = "scenario=install scenariosubtype=ARP sourcetype=None productstoremove=O365HomePremRetail.16_en-us_x-none culture=en-us version.16=16.0 forceappshutdown=true DisplayLevel=False"
                    Start-Process -FilePath $UninstallEXE -ArgumentList $UninstallArg -Wait
                    #  Verify uninstall
                    if (!(get-package "*$program*")){Write-Host -Object "Successfully uninstalled: [$Program]"}
                    #  If uninstall failed, warn user
                    Else {Write-Warning -Message "Failed to uninstall: [$Program]"}
                }
            }
            Catch {Write-Warning -Message "Failed to uninstall: [$Program]"} #  If uninstall fails, run catch, warning user
        }
        else{Write-Host "[$Program] was not installed"} #  Notify user that program is not installed
    }
#
#  Uninstall OneDrive 
#
    elseif($Program -eq "OneDrive"){
        If (Get-package -name "*$Program*" -ErrorAction SilentlyContinue){ #  Use built-in cmdlet to check if program is installed
            #  If installed, find the directory it's installed and save that filepath to a variable
            if (test-path "C:\Program Files (x86)\Microsoft OneDrive\*\OneDriveSetup.exe"){ $OneDrivePath = "C:\Program Files (x86)\Microsoft OneDrive\*\OneDriveSetup.exe"}
            elseif (test-path "C:\Users\local_admin\AppData\Local\Microsoft\OneDrive\*\OneDriveSetup.exe"){ $OneDrivePath = "C:\Users\local_admin\AppData\Local\Microsoft\OneDrive\*\OneDriveSetup.exe"}
            Try { #  Attempt uninstall
                & $OneDrivePath /uninstall #/allusers  Not sure if the AllUsers switch will work...Leave it so it can be tested in future if needed
                #  Verify uninstall
                if (!(get-package "*$program*")){Write-Host -Object "Successfully uninstalled: [$Program]"}
                #  If uninstall failed, warn user
                Else {Write-Warning -Message "Failed to uninstall: [$Program]"}
            }
            Catch {Write-Warning -Message "Failed to uninstall: [$Program]"} #  If uninstall fails, run catch, warning user
        }
        else{Write-Host "[$Program] not installed"} #  Notify user that program is not installed
    }
<#                
#
#  Uninstall Xbox Services
#
    elseif($Program -eq "XBOX"){
        $program = "XBOX"
        If (Get-AppxPackage -name "*$Program*" -ErrorAction SilentlyContinue){ #  Use built-in cmdlet to check if program is installed
            Try { #  Attempt uninstall
                $Null = Get-ProvisionedAppxPackage -Online | `
                    Where-Object { $_.PackageName -match "xbox" } | `
                    ForEach-Object { Remove-ProvisionedAppxPackage -Online -AllUsers -PackageName $_.PackageName }
                Write-Host -Object "Successfully uninstalled: [$Program]"
            }
            Catch {Write-Warning -Message "Failed to uninstall: [$Program]"} #  If uninstall fails, run catch, warning user
        }
        else{Write-Host "$Program not installed"} #  Notify user that program is not installed
    }
    #>            
#
#  Uninstall Dell Delivery Services    
#
    elseif($Program -eq "Dell Digital Delivery Services"){
        If (Get-package -name "*$Program*" -ErrorAction SilentlyContinue){
            Try { #  Attempt uninstall
                $Null = Get-package -name "*$Program*" | Uninstall-Package -AllVersions -Force -ErrorAction Stop
                #  Verify uninstall
                if (!(get-package "*$program*")){Write-Host -Object "Successfully uninstalled: [$Program]"}
                #  If uninstall failed, warn user
                Else {Write-Warning -Message "Failed to uninstall: [$Program]"}
            }
            Catch {Write-Warning -Message "Failed to uninstall: [$Program]"} #  If uninstall fails, run catch, warning user
        }
        else{Write-Host "$Program not installed"} #  Notify user that program is not installed
    }            
#
#  Uninstall WebAdvisor by McAfee    
#
    elseif($Program -eq "WebAdvisor"){
        #  Check registry for program
        $WebAdvisorString = get-itemproperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' | ? { $_.DisplayName -match "$Program"}  -ErrorAction SilentlyContinue
        If ($WebAdvisorString){
            Try { #  Attempt uninstall
                # C:\Program Files\McAfee\WebAdvisor\Uninstaller.exe
                cmd /c $WebAdvisorString.uninstallstring /s
                #  Verify uninstall
                if (!(get-package "*$program*")){Write-Host -Object "Successfully uninstalled: [$Program]"}
                #  If uninstall failed, warn user
                Else {Write-Warning -Message "Failed to uninstall: [$Program]"}
            }
            Catch {Write-Warning -Message "Failed to uninstall: [$Program]"} #  If uninstall fails, run catch, warning user
        }
        else{Write-Host "$Program not installed"} #  Notify user that program is not installed
    }    

#
#  Progress bar
#
    $i += 1
    $progress = (($i / $ProgramList.Count)*100).tostring("##.##")
    Write-Progress -Activity "Uninstalling Programs..." -Status $progress% -PercentComplete $progress

}

#  Build array for final verification of uninstall
$verify = @(
    "Dell Optimizer Service"
    "MyDell"
    "Dell Digital Delivery Services"
    "Microsoft OneDrive"
    "Microsoft OneNote"
    "Microsoft 365"
    "WebAdvisor by McAfee"
)

#  Test if each program has been uninstalled and produce report.
$report = foreach($app in $verify){
    if(get-package *$app*){Write-Warning (get-package *$app*).name "failed to uninstall."}
    else{Write-Host (Get-Package *$app*).name "uninstalled sucessfully." -ForegroundColor Cyan}
}

#  Include the hostname and date in report. Then place report on the current users desktop.
#  If an existing report is on the desktop, it WILL be overwritten.
$report
hostname > ~\desktop\Uninstall_Report.txt
get-date >> ~\desktop\Uninstall_Report.txt
$report >> ~\desktop\Uninstall_Report.txt

<#
#
#  Reboot Required?
#
$input = Read-Host "Restart computer now [y/n]"
switch($input){
          y{Restart-computer -Force -Confirm:$false}
          n{exit}
    default{write-warning "Skipping reboot."}
}
#>