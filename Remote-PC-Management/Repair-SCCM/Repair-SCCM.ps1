<# Broken SCCM
CSOON033
CSHAW002
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
$COMPUTERS = @( "CSHAW002" )
#$COMPUTERS = Get-Content # Pull from txt file
Write-Host "Building connections to targets." -ForegroundColor Yellow
$SESSIONS = New-PSSession -ComputerName $COMPUTERS

# SCCM reinstall script
foreach ( $SESSION in $SESSIONS ){
    $SESSION.computername
    Invoke-Command -Session $SESSIONS -ScriptBlock {
        try {
	        # Check if SCCM Client is installed
	        $CLIENTPATH = "C:\Windows\CCM\CcmExec.exe"
	        if ( -Not ( Test-Path $CLIENTPATH )){
                Throw "Cannot find CcmExec.exe. SCCM Client is not installed."
	        }
				
	        # Check if SCCM Client Service is running
	        $SERVICE = Get-Service -Name CcmExec -ErrorAction SilentlyContinue
	        if ( $SERVICE.Status -ne 'Running' ) {
                Throw "Found CcmExec service but it is NOT running."
            } Else {
		        Throw "CcmExec service could not be found. SCCM Client may not be installed."
	        }

            # Check Client Version
            $SMSCLIENT = Get-WmiObject -Namespace "root\ccm" -Class SMS_Client -ErrorAction SilentlyContinue
            if ( -not ( $SMSCLIENT.ClientVersion )) {
                Throw "SMS_Client.ClientVersion class not found. SCCM Client may not be installed."
            }    

            # Check Management Point Communication
            $MP = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
            if ( -not ( $MP.Name )) {
                Throw "SMS_Authority.Name property not found. SCCM Client may not be installed."
            }

            # Check Client ID
            $CCMCLIENT = Get-WmiObject -Namespace "root\ccm" -Class CCM_Client -ErrorAction SilentlyContinue
            if ( -not ( $CCMCLIENT.ClientId )) {
                Throw "CCM_Client.ClientId property not found. SCCM Client may not be installed."
            }   
    
            # Check Management Point Communication
            $MP = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
            if ( -not ( $MP.CurrentManagementPoint )) {
                Throw "SMS_Authority.CurrentManagementPoint property not found. SCCM Client may not be installed."
            }

            # Check SCCM Client Health Evaluation (Using CCMEval Logs)
            $CCMEVAL_LOGPATH = "C:\Windows\CCM\Logs\CCMEval.log"
            if ( Test-Path $CCMEVAL_LOGPATH ) {
        
                # Get the current date and calculate the date a week ago
                $LASTWEEK_DATE = $( Get-Date ).AddDays( -7 )

                # Regex pattern to match log entries with dates
                $PATTERN = '<time=".*?" date="(\d{2})-(\d{2})-(\d{4})"'

                # Read the log file and filter logs from the last week
                $FILTERED_LOGS = Get-Content $CCMEVAL_LOGPATH -Raw | Where-Object {
                    if ( $_ -match $PATTERN ) {
                        $LOG_DATE = Get-Date "$( $MATCHES[1] )/$( $MATCHES[2] )/$( $MATCHES[3] )" -Format "MM/dd/yyyy"
                        [datetime]$LOG_DATE -ge $LASTWEEK_DATE
                    }
                }

                $CCMEVAL_RESULTS = $FILTERED_LOGS | findstr /i fail

                if ( $CCMEVAL_RESULTS ) {
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
            Write-Host "An error occurred: $($_)" -ForegroundColor Cyan
            Write-Host "Running all repair actions..."
        
            # Remove certs and restart service
            # Possible this is the only needed fix.
            # Run this first step and then test if it worked before continuing. 
            Write-Host "(Step 1 of 6) Stopping CcmExec to remove SMS certs." -ForegroundColor Yellow
            $FOUND = Get-Service CcmExec -ErrorAction SilentlyContinue
            if ( $FOUND ){
                Stop-Service CcmExec -ErrorAction SilentlyContinue
                do {
                    Start-Sleep -Seconds 3
                    $SERVICESTATUS = Get-Service -Name CcmExec
                } while ($SERVICESTATUS.Status -ne 'Stopped')
                Get-ChildItem Cert:\LocalMachine\SMS | Remove-Item
                Start-Service CcmExec -ErrorAction SilentlyContinue

                # Verify service start
                Start-Sleep -Seconds 5  # Allow some time for the service to start
                $SERVICESTATUS = Get-Service -Name CcmExec

                # Announce success/fail
                if ( $SERVICESTATUS.Status -eq 'Running' ) {
                    Write-Host "Service restarted successfully. Check if issue is resolved. Ending actions on current target." -ForegroundColor Yellow
                    Write-Host "Disconnecting from current session and moving to the next target." -ForegroundColor Yellow
                    $PSSENDERINFO = $( $EXECUTIONCONTEXT.SessionState.PSVariable.GetValue( "PSSenderInfo" ))
                    if ( $PSSENDERINFO ) {
                        Remove-PSSession -Id $PSSENDERINFO.SessionId
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
            $SERVICES = @(
                "ccmexec",
                "ccmsetup"
            )
            foreach ( $SERVICE in $SERVICES ){
                if (get-service $SERVICE){
                    Stop-Service $SERVICE -Force
                    sc delete $SERVICE
                } else{
                    Write-Host "$SERVICE service not found. Continuing."
                }        
            }

            # Delete the folders for SCCM
            Write-Host "(Step 4 of 6) Deleting all SCCM folders and files." -ForegroundColor Yellow
            $FILES = @(
                "C:\Windows\CCM",
                "C:\Windows\ccmcache",
                "C:\Windows\ccmsetup",
                "C:\Windows\SMSCFG.ini"
            )
            foreach ( $FILE in $FILES ){
                if ( Test-Path $FILE ){
                    Remove-Item $FILE -Recurse -Force
                } else{
                    Write-Host "$FILE not found. Continuing."
                }
            }

            # Delete the main registry keys associated with SCCM
            Write-Host "(Step 5 of 6) Deletinag all SCCM reg keys." -ForegroundColor Yellow
            $KEYS = @(
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
            foreach ( $KEY in $KEYS ){
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
            Invoke-Command -Session $SESSIONS -ScriptBlock {
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
    }
    Write-Host ""
}
Remove-PSSession *  # Clean up sessions after use
