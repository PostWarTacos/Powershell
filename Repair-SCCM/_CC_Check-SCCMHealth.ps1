# Creates an Arraylist which is mutable and easier to manipulate than an array.
$RESULTS = [System.Collections.ArrayList]@()

# Check if SCCM Client is installed
$CLIENTPATH = "C:\Windows\CCM\CcmExec.exe"
if ( Test-Path $CLIENTPATH ){
    $RESULTS.Add("Found CcmExec.exe. SCCM installed.")
} Else {
	$RESULTS.Add("Cannot find CcmExec.exe. SCCM Client is not installed.")
}
				
# Check if SCCM Client Service is running
$SERVICE = Get-Service -Name CcmExec -ErrorAction SilentlyContinue
if ( $SERVICE.Status -eq 'Running' ){
    $RESULTS.Add("Found CcmExec service and it is running.")
} Elseif ( $SERVICE.Status -ne 'Running' ) {
    $RESULTS.Add("Found CcmExec service but it is NOT running.")
} Else {
	$RESULTS.Add("CcmExec service could not be found. SCCM Client may not be installed.")
}

# Check Client Version
$SMSCLIENT = Get-WmiObject -Namespace "root\ccm" -Class SMS_Client -ErrorAction SilentlyContinue
if ( $SMSCLIENT.ClientVersion ) {
    $RESULTS.Add("SCCM Client Version: $( $SMSCLIENT.ClientVersion )")
} else {
    $RESULTS.Add("SMS_Client.ClientVersion class not found. SCCM Client may not be installed.")
}    

# Check Management Point Communication
$MP = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
if ( $MP.Name ) {
    $RESULTS.Add("SCCM Site found: $( $MP.Name )")
} else {
    $RESULTS.Add("SMS_Authority.Name property not found. SCCM Client may not be installed.")
}

# Check Client ID
$CCMCLIENT = Get-WmiObject -Namespace "root\ccm" -Class CCM_Client -ErrorAction SilentlyContinue
if ( $CCMCLIENT.ClientId ) {
    $RESULTS.Add("SCCM Client Client ID found: $( $CCMCLIENT.ClientId )")
} else {
    $RESULTS.Add("CCM_Client.ClientId property not found. SCCM Client may not be installed.")
}   
    
# Check Management Point Communication
$MP = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
if ( $MP.CurrentManagementPoint ) {
    $RESULTS.Add("SCCM Management Point found: $( $MP.CurrentManagementPoint )")
} else {
    $RESULTS.Add("SMS_Authority.CurrentManagementPoint property not found. SCCM Client may not be installed.")
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

    # Searches filtered logs (last week) for the string "fail."
    $CCMEVAL_RESULTS = $FILTERED_LOGS | findstr /i fail

    if ( $CCMEVAL_RESULTS ) {
        $RESULTS.Add("SCCM Client health check failed per CCMEval logs.")
    } else {
        $RESULTS.Add("SCCM Client passed health check per CCMEval logs.")
    }
} else {
    $RESULTS.Add("CCMEval log not found. Unable to verify SCCM Client health.")
}

return $RESULTS