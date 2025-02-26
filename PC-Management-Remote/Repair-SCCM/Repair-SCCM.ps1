<#
#   Intent: Based on US AFCENT System Center Configuration Manger Current Branch (SCCM-CB)
#       guide to troubleshoot and repair SCCM clients
#   Date: 24-Feb-25
#   Author: Matthew Wurtz
#>

<# SCCM Reinstall

1. Delete SMS certs and reload service. Test if fixed, end actions if it is.

2. Clean uninstall

3. Remove both services “ccmsetup” and “SMS Agent Host”

4. Delete the folders for SCCM

5. Delete the main registries associated with SCCM

6. Install from \\slrcp223\SMS_PCI\Client\ccmsetup.exe

7. Manually reinstall

Sometimes AV stops the reinstall. Kill AV solution. 

    a.  Reinstall vcredist_x64.exe / vcredist_x86.exe (possible locations listed below)
        i.   C:\Windows\ccmsetup\vcredist_x64.exe
        ii.  \\slrcp223\SMS_PCI\Client\x64\vcredist_x64.exe
    b.	Run CCMSETUP again

#>

Clear-Host

# Creates an Arraylist which is mutable and easier to manipulate than an array.
$healthLogPath = "C:\drivers\CCM\Logs\"


try {
    # Check if SCCM Client is installed
    $clientPath = "C:\Windows\CCM\CcmExec.exe"
    if ( -Not ( Test-Path $clientPath )){
        Throw "Cannot find CcmExec.exe. SCCM Client is not installed."
    }
        
    # Check if SCCM Client Service is running
    $service = Get-Service -Name CcmExec -ErrorAction SilentlyContinue
    if ( $service.Status -and $service.Status -eq 'Running' ){
        # Do nothing. Just here to ensure 'Running' never triggers 'Else'
    } elseif ( $service.Status -and $service.Status -ne 'Running' ) {
        Throw "Found CcmExec service but it is NOT running."
    } Else {
        Throw "CcmExec service could not be found. SCCM Client may not be installed."
    }

    # Check Client Version
    $smsClient = Get-WmiObject -Namespace "root\ccm" -Class SMS_Client -ErrorAction SilentlyContinue
    if ( -not ( $smsClient.ClientVersion )) {
        Throw "SMS_Client.ClientVersion class not found. SCCM Client may not be installed."
    }    

    # Check Management Point Communication
    $mp = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
    if ( -not ( $mp.Name )) {
        Throw "SMS_Authority.Name property not found. SCCM Client may not be installed."
    }

    # Check Client ID
    $ccmClient = Get-WmiObject -Namespace "root\ccm" -Class CCM_Client -ErrorAction SilentlyContinue
    if ( -not ( $ccmClient.ClientId )) {
        Throw "CCM_Client.ClientId property not found. SCCM Client may not be installed."
    }   

    # Check Management Point Communication
    $mp = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
    if ( -not ( $mp.CurrentManagementPoint )) {
        Throw "SMS_Authority.CurrentManagementPoint property not found. SCCM Client may not be installed."
    }

    # Check SCCM Client Health Evaluation (Using CCMEval Logs)
    $ccmEvalLogPath = "C:\Windows\CCM\Logs\CCMEval.log"
    if ( Test-Path $ccmEvalLogPath ) {

        # Get the current date and calculate the date a week ago
        $lastWeekDate = $( Get-Date ).AddDays( -7 )

        # Regex pattern to match log entries with dates
        $pattern = '<time=".*?" date="(\d{2})-(\d{2})-(\d{4})"'

        # Read the log file and filter logs from the last week
        $filteredLogs = Get-Content $ccmEvalLogPath -Raw | Where-Object {
            if ( $_ -match $pattern ) {
                $logDate = Get-Date "$( $matches[1] )/$( $matches[2] )/$( $matches[3] )" -Format "MM/dd/yyyy"
                [datetime]$logDate -ge $lastWeekDate
            }
        }

        $ccmEvalResults = $filteredLogs | findstr /i fail

        if ( $ccmEvalResults ) {
            Throw "SCCM Client health check failed per CCMEval logs."
        } 
    } else {
        Throw "CCMEval log not found. Unable to verify SCCM Client health."
    }

    # If everything is fine, return 0
    Write-Host "SCCM Client is healthy."
    return 0
}
catch {
    "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $($_)" >> "$healthLogPath\HealthCheck.txt" 
    "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Attempting repair actions." >> "$healthLogPath\HealthCheck.txt" 
    Write-Host "An error occurred: $($_)" -ForegroundColor Cyan
    Write-Host "Running all repair actions..."

    # Remove certs and restart service
    # Possible this is the only needed fix.
    # Run this first step and then test if it worked before continuing. 
    Write-Host "(Step 1 of 6) Stopping CcmExec to remove SMS certs." -ForegroundColor Yellow
    $found = Get-Service CcmExec -ErrorAction SilentlyContinue
    if ( $found ){
        Stop-Service CcmExec -ErrorAction SilentlyContinue -Force
        do {
            Start-Sleep -Seconds 3
            $service = Get-Service -Name CcmExec
        } while ($_.Status -ne 'Stopped')
        Get-ChildItem Cert:\LocalMachine\SMS | Remove-Item
        Start-Service CcmExec -ErrorAction SilentlyContinue

        # Verify service start
        Start-Sleep -Seconds 5  # Allow some time for the service to start
        $service = Get-Service -Name CcmExec

        # Announce success/fail
        if ( $service.Status -eq 'Running' ) {
            Write-Host "Service restarted successfully. Manually check if issue is resolved. Ending actions on current target." -ForegroundColor Yellow
            Write-Host "Disconnecting from current session and moving to the next target." -ForegroundColor Yellow
            #$sessionId = $PSSession.Id
            $psSenderInfo = $( $EXECUTIONCONTEXT.SessionState.PSVariable.GetValue( "PSSenderInfo" ))
            if ( $psSenderInfo ) {
                Remove-PSSession -Id $psSenderInfo.SessionId
            }
            return
        } else {
            Write-Host "Failed to start service. Continuing with SCCM Client repair." -ForegroundColor Yellow
        }
    } Else {
        Write-Host "CcmExec Service not installed."
    }

    # Clean uninstall
    Write-Host "(Step 2 of 6) Performing complete clean uninstall." -ForegroundColor Yellow
    if ( Test-Path C:\Windows\ccmsetup\ccmsetup.exe ){
        C:\Windows\ccmsetup\ccmsetup.exe /uninstall
    } else {
        Write-Host "Ccmsetup.exe not found. Continuing."
    }

    # Remove both services “ccmsetup” and “SMS Agent Host”
    Write-Host "(Step 3 of 6) Stopping and removing CcmExec and CcmSetup services." -ForegroundColor Yellow
    $services = @(
        "ccmexec",
        "ccmsetup"
    )
    foreach ( $service in $services ){
        if (get-service $service){
            Stop-Service $service -Force
            sc delete $service
        } else{
            Write-Host "$service service not found. Continuing."
        }        
    }

    # Delete the folders for SCCM
    Write-Host "(Step 4 of 6) Deleting all SCCM folders and files." -ForegroundColor Yellow
    $files = @(
        "C:\Windows\CCM",
        "C:\Windows\ccmcache",
        "C:\Windows\ccmsetup",
        "C:\Windows\SMSCFG.ini"
    )
    foreach ( $file in $files ){
        if ( Test-Path $file ){
            Remove-Item $file -Recurse -Force
        } else{
            Write-Host "$file not found. Continuing."
        }
    }

    # Delete the main registry keys associated with SCCM
    Write-Host "(Step 5 of 6) Deletinag all SCCM reg keys." -ForegroundColor Yellow
    $keys= @(
        "HKLM:\Software\Microsoft\CCM",
        "HKLM:\Software\Microsoft\SMS",
        "HKLM:\Software\Microsoft\ccmsetup",
        "HKLM:\Software\Wow6432Node\Microsoft\CCM",
        "HKLM:\Software\Wow6432Node\Microsoft\SMS",
        "HKLM:\Software\Wow6432Node\Microsoft\ccmsetup",
        "HKLM:\System\CurrentControlSet\Services\CcmExec",
        "HKLM:\System\CurrentControlSet\Services\prepdrvr",
        "HKLM:\System\CurrentControlSet\Services\eventlog\Application\Configuration Manager Agent"
    )
    foreach ( $key in $keys ){
        if( Test-Path $KEY ){
            Remove-Item $KEY -Force
        } Else { Write-Host "Could not find $KEY. Continuing." }    
    }

    # Reinstall SCCM via \\slrcp223\SMS_PCI\Clientccmsetup.exe
    Write-Host "(Step 6 of 6) Attempting reinstall." -ForegroundColor Yellow    
    & "\\slrcp223\SMS_PCI\Clientccmsetup.exe /logon SMSSITECODE=PCI" # Might need to add switches. In discussion

    # Might need to add step 7.
    <#
    Manually reinstall vcredist_x64

    Sometimes AV stops the reinstall. Kill AV solution. 

    a.  Reinstall vcredist_x64.exe / vcredist_x86.exe (possible locations listed below)
        i.   C:\Windows\ccmsetup\vcredist_x64.exe
        ii.  \\slrcp223\SMS_PCI\Client\x64\vcredist_x64.exe
    b.	Run CCMSETUP again
    #>

    # Reinstall BITS script
    <#
    Invoke-Command -Session $sessions -ScriptBlock {
        sc sdset bits "D:(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)S:(AU;SAFA;WDWO;;;BA)"
        sc config bits start= auto
        Remove-Item -Path "$ENV:ALLUSERSPROFILE\Application Data\Microsoft\Network\Downloader\qmgr0.dat" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$ENV:ALLUSERSPROFILE\Application Data\Microsoft\Network\Downloader\qmgr1.dat" -Force -ErrorAction SilentlyContinue
        Start-Service -Name bits
    }
    #>

    # Reinstall BITS - Method 2
    <#
    These commands will reset the permissions on 4 dependent services, set them to automatic start, and try to start the services.

    sc sdset RpcEptMapper "D:(A;;CCLCLORC;;;AU)(A;;CCDCLCSWRPWPDTLORCWDWO;;;SY)(A;;CCLCSWRPWPDTLORCWDWO;;;BA)(A;;CCLCRPLO;;;BU)S:(AU;FA;CCDCLCSWRPWPDTLOSDRCWDWO;;;WD)"
    sc sdset DcomLaunch   "D:(A;;CCLCLORC;;;AU)(A;;CCDCLCSWRPWPDTLORCWDWO;;;SY)(A;;CCLCSWRPWPDTLORCWDWO;;;BA)(A;;CCLCLO;;;BU)S:(AU;FA;CCDCLCSWRPWPDTLOSDRCWDWO;;;WD)"
    sc sdset RpcSs        "D:(A;;CCLCLORC;;;AU)(A;;CCDCLCSWRPWPDTLORCWDWO;;;SY)(A;;CCLCSWRPWPDTLORCWDWO;;;BA)(A;;CCLCLO;;;BU)S:(AU;FA;CCDCLCSWRPWPDTLOSDRCWDWO;;;WD)"
    sc sdset EventSystem  "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)S:(AU;FA;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;WD)"

    sc config RpcEptMapper start= auto
    sc config DcomLaunch start= auto
    sc config RpcSs start= auto
    sc config EventSystem start= auto

    net start RpcEptMapper
    net start DcomLaunch
    net start RpcSs
    net start EventSystem
    #>

    return 1
}