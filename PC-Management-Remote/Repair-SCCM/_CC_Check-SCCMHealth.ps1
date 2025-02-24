# Creates an Arraylist which is mutable and easier to manipulate than an array.
$results = [System.Collections.ArrayList]@()

# Check if SCCM Client is installed
$clientPath = "C:\Windows\CCM\CcmExec.exe"
if ( Test-Path $clientPath ){
    $results.Add( "Found CcmExec.exe. SCCM installed." ) | Out-Null
} Else {
	$results.Add( "Cannot find CcmExec.exe. SCCM Client is not installed." ) | Out-Null
}
				
# Check if SCCM Client Service is running
$service = Get-Service -Name CcmExec -ErrorAction SilentlyContinue
if ( $service.Status -eq 'Running' ){
    $results.Add( "Found CcmExec service and it is running." ) | Out-Null
} Elseif ( $service.Status -ne 'Running' ) {
    $results.Add( "Found CcmExec service but it is NOT running." ) | Out-Null
} Else {
	$results.Add( "CcmExec service could not be found. SCCM Client may not be installed." ) | Out-Null
}

# Check Client Version
$smsClient = Get-WmiObject -Namespace "root\ccm" -Class SMS_Client -ErrorAction SilentlyContinue
if ( $smsClient.ClientVersion ) {
    $results.Add( "SCCM Client Version: $( $smsClient.ClientVersion )" ) | Out-Null
} else {
    $results.Add( "SMS_Client.ClientVersion class not found. SCCM Client may not be installed." ) | Out-Null
}    

# Check Management Point Communication
$mp = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
if ( $mp.Name ) {
    $results.Add( "SCCM Site found: $( $MP.Name )" ) | Out-Null
} else {
    $results.Add( "SMS_Authority.Name property not found. SCCM Client may not be installed." ) | Out-Null
}

# Check Client ID
$ccmClient = Get-WmiObject -Namespace "root\ccm" -Class CCM_Client -ErrorAction SilentlyContinue
if ( $ccmClient.ClientId ) {
    $results.Add( "SCCM Client Client ID found: $( $ccmClient.ClientId )" ) | Out-Null
} else {
    $results.Add( "CCM_Client.ClientId property not found. SCCM Client may not be installed." ) | Out-Null
}   
    
# Check Management Point Communication
$mp = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
if ( $mp.CurrentManagementPoint ) {
    $results.Add( "SCCM Management Point found: $( $mp.CurrentManagementPoint )" ) | Out-Null
} else {
    $results.Add( "SMS_Authority.CurrentManagementPoint property not found. SCCM Client may not be installed." ) | Out-Null
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
        $results.Add( "SCCM Client health check failed per CCMEval logs." ) | Out-Null
    } else {
        $results.Add( "SCCM Client passed health check per CCMEval logs." ) | Out-Null
    }
} else {
    $results.Add( "CCMEval log not found. Unable to verify SCCM Client health." ) | Out-Null
}

$results = $results -join ','
return $results