clear
$COMPUTERS = @( "CSHAW002" )
#$COMPUTERS = Get-Content # Pull from txt file
Write-Host "Building connections to targets." -ForegroundColor Yellow
$SESSIONS = New-PSSession -ComputerName $COMPUTERS

Invoke-Command -Session $SESSIONS {
	# Check if SCCM Client is installed
	$CLIENTPATH = "C:\Windows\CCM\CcmExec.exe"
	if ( Test-Path $CLIENTPATH ){
        Write-Host "Found CcmExec.exe. SCCM installed."
    } Else {
		Write-Host "Cannot find CcmExec.exe. SCCM Client is not installed." -ForegroundColor Cyan
	}
				
	# Check if SCCM Client Service is running
	$SERVICE = Get-Service -Name CcmExec -ErrorAction SilentlyContinue
	if ( $SERVICE.Status -eq 'Running' ){
        Write-Host "Found CcmExec service and it is running."
    } Elseif ( $SERVICE.Status -ne 'Running' ) {
        Write-Host "Found CcmExec service but it is NOT running." -ForegroundColor Cyan
    } Else {
		Write-Host "CcmExec service could not be found. SCCM Client may not be installed." -ForegroundColor Cyan
	}

    # Check Client Version
    $SMSCLIENT = Get-WmiObject -Namespace "root\ccm" -Class SMS_Client -ErrorAction SilentlyContinue
    if ( $SMSCLIENT.ClientVersion ) {
        Write-Host "SCCM Client Version: $( $SMSCLIENT.ClientVersion )"
    } else {
        Write-Host "SMS_Client.ClientVersion class not found. SCCM Client may not be installed." -ForegroundColor Cyan
    }    

    # Check Management Point Communication
    $MP = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
    if ( $MP.Name ) {
        Write-Host "SCCM Site found: $( $MP.Name )"
    } else {
        Write-Host "SMS_Authority.Name property not found. SCCM Client may not be installed." -ForegroundColor Cyan
    }

    # Check Client ID
    $CCMCLIENT = Get-WmiObject -Namespace "root\ccm" -Class CCM_Client -ErrorAction SilentlyContinue
    if ( $CCMCLIENT.ClientId ) {
        Write-Host "SCCM Client Client ID found: $( $CCMCLIENT.ClientId )"
    } else {
        Write-Host "CCM_Client.ClientId property not found. SCCM Client may not be installed." -ForegroundColor Cyan
    }   
    
    # Check Management Point Communication
    $MP = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
    if ( $MP.CurrentManagementPoint ) {
        Write-Host "SCCM Management Point found: $( $MP.CurrentManagementPoint )"
    } else {
        Write-Host "SMS_Authority.CurrentManagementPoint property not found. SCCM Client may not be installed." -ForegroundColor Cyan
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
            Write-Host "SCCM Client health check failed per CCMEval logs." -ForegroundColor Cyan
        } else {
            Write-Host "SCCM Client passed health check per CCMEval logs."
        }
    } else {
        Write-Host "CCMEval log not found. Unable to verify SCCM Client health." -ForegroundColor Cyan
    }
}

Remove-PSSession *
