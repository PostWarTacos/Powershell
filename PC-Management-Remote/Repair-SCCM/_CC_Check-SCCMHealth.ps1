# Creates an Arraylist which is mutable and easier to manipulate than an array.
$healthLog = [System.Collections.ArrayList]@()
$healthLogPath = "C:\drivers\CCM\Logs"
$corruption = 0

# Check if SCCM Client is installed
$clientPath = "C:\Windows\CCM\CcmExec.exe"
if ( Test-Path $clientPath ){
    $healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Found CcmExec.exe. SCCM installed." ) | Out-Null
} Else {
	$healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Cannot find CcmExec.exe. SCCM Client is not installed." ) | Out-Null
    $corruption += 1
}
				
# Check if SCCM Client Service is running
$service = Get-Service -Name CcmExec -ErrorAction SilentlyContinue
if ( $service.Status -eq 'Running' ){
    $healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Found CcmExec service and it is running." ) | Out-Null
} Elseif ( $service.Status -ne 'Running' ) {
    $healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Found CcmExec service but it is NOT running." ) | Out-Null
    $corruption += 1
} Else {
	$healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: CcmExec service could not be found. SCCM Client may not be installed." ) | Out-Null
    $corruption += 1
}

# Check Client Version
$smsClient = Get-WmiObject -Namespace "root\ccm" -Class SMS_Client -ErrorAction SilentlyContinue
if ( $smsClient.ClientVersion ) {
    $healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SCCM Client Version: $( $smsClient.ClientVersion )" ) | Out-Null
} else {
    $healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SMS_Client.ClientVersion class not found. SCCM Client may not be installed." ) | Out-Null
    $corruption += 1
}    

# Check Management Point Communication
$mp = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
if ( $mp.Name ) {
    $healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SCCM Site found: $( $MP.Name )" ) | Out-Null
} else {
    $healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SMS_Authority.Name property not found. SCCM Client may not be installed." ) | Out-Null
    $corruption += 1
}

# Check Client ID
$ccmClient = Get-WmiObject -Namespace "root\ccm" -Class CCM_Client -ErrorAction SilentlyContinue
if ( $ccmClient.ClientId ) {
    $healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SCCM Client Client ID found: $( $ccmClient.ClientId )" ) | Out-Null
} else {
    $healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: CCM_Client.ClientId property not found. SCCM Client may not be installed." ) | Out-Null
    $corruption += 1
}   
    
# Check Management Point Communication
$mp = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
if ( $mp.CurrentManagementPoint ) {
    $healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SCCM Management Point found: $( $mp.CurrentManagementPoint )" ) | Out-Null
} else {
    $healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SMS_Authority.CurrentManagementPoint property not found. SCCM Client may not be installed." ) | Out-Null
    $corruption += 1
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

    # Searches filtered logs (last week) for the string "fail."
    $ccmEvalResults = $filteredLogs | findstr /i fail

    if ( $ccmEvalResults ) {
        $healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SCCM Client health check failed per CCMEval logs." ) | Out-Null
        $corruption += 1
    } else {
        $healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SCCM Client passed health check per CCMEval logs." ) | Out-Null
    }
} else {
    $healthLog.Add( "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: CCMEval log not found. Unable to verify SCCM Client health." ) | Out-Null
    $corruption += 1
}

if ( $corruption -eq 0 ){
    $results = "Client Healthy"
} else {
    $results = "Corrupt Client"
}

if ( -not ( Test-Path $healthLogPath )){
    mkdir $healthLogPath
}

$healthLog >> $healthLogPath
return $results