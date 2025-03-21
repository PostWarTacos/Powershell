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



function Stop-ServiceWithTimeout {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServiceName,

        [int]$TimeoutSeconds = 30
    )

    Write-Host "Attempting to stop service: $ServiceName"
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        Start-Sleep -Seconds 1
        $elapsed++

        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($null -eq $service -or $service.Status -eq 'Stopped') {
            Write-Host "Service $ServiceName stopped successfully."
            break
        }
        else{
            Write-Host "Waiting for service to stop... ($elapsed/$TimeoutSeconds)"
        }
    }

    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($null -eq $service -or $service.Status -eq 'Stopped') {
        # do nothing
    }
    else{
        # If the service is still running after the timeout, force kill the process
        Write-Host "Timeout reached! Forcefully terminating the service process."
        $serviceProcess = Get-WmiObject Win32_Service | Where-Object { $_.Name -eq $ServiceName }
        if ( $serviceProcess -and $serviceProcess.ProcessId -ne 0 ) {
            Stop-Process -Id $serviceProcess.ProcessId -Force -ErrorAction SilentlyContinue
            Write-Host "Service process terminated."
        } else {
            Write-Host "Service was already stopped or process not found."
        }
    }
}

#============
# MAIN SCRIPT
#============

Clear-Host

# Creates an Arraylist which is mutable and easier to manipulate than an array.
$healthLog = [System.Collections.ArrayList]@()
$message = "Attempting repair actions."
$healthLogPath = "C:\drivers\CCM\Logs\"
If( -not ( Test-Path $healthLogPath )) {
    mkdir $healthLogPath
}
$healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
write-host $message -ForegroundColor Cyan

# Remove certs and restart service
# Possible this is the only needed fix.
# Run this first step and then test if it worked before continuing. 
Write-Host "(Step 1 of 8) Stopping CcmExec to remove SMS certs." -ForegroundColor Cyan
$found = Get-Service CcmExec -ErrorAction SilentlyContinue | Where-Object status -ne "stopped"
if ( $found ){
    Stop-ServiceWithTimeout CcmExec
    write-host "Removing SMS certs."
    Get-ChildItem Cert:\LocalMachine\SMS | Remove-Item
    Start-Service CcmExec -ErrorAction SilentlyContinue

    # Start service
    Start-Sleep -Seconds 10 # Allow some time for the service to start

    # Attempt to contact MP and pull new policy. If this works, client should be healthy.
    $policyUpdate = Invoke-WmiMethod -Namespace "root\ccm" -Class "SMS_Client" -Name "TriggerSchedule" -ArgumentList "{00000000-0000-0000-0000-000000000021}"
    $logPath = "C:\Windows\CCM\Logs\PolicyAgent.log"
    $recentLogs = Get-Content $logPath -Tail 50
    $patterns = @(
        "Updated namespace .* successfully",
        "Successfully received policy assignments from MP",
        "PolicyAgent successfully processed the policy assignment",
        "Completed policy evaluation cycle"
    )
                             
    $success = $recentLogs | Select-String -Pattern $patterns
    
    # Announce success/fail
    if ( $success ) {
        $message = "Service restarted successfully and MP contacted. Assuming resolved, ending script."
        $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message Ending actions on current target.") | Out-Null
        #$sessionId = $PSSession.Id
        $psSenderInfo = $( $EXECUTIONCONTEXT.SessionState.PSVariable.GetValue( "PSSenderInfo" ))
        if ( $psSenderInfo ) {
            Remove-PSSession -Id $psSenderInfo.SessionId
        }
        write-host $message -ForegroundColor Green
    } else {
        $message = "Failed to start service. Continuing with SCCM Client repair."
        $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
        write-host $message -ForegroundColor Yellow
    }
} Else {
    $message = "CcmExec Service not installed. Continuing with SCCM Client repair."
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
    write-host $message -ForegroundColor Yellow
}

# Clean uninstall
Write-Host "(Step 2 of 8) Performing complete clean uninstall." -ForegroundColor Cyan
if ( Test-Path C:\Windows\ccmsetup\ccmsetup.exe ){
    C:\Windows\ccmsetup\ccmsetup.exe /uninstall
    $message = "Ccmsetup.exe uninstalled. Continuing."
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
    write-host $message -ForegroundColor Green
} else {
    $message = "Ccmsetup.exe not found. Continuing."
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
    write-host $message -ForegroundColor Yellow
}

# Remove both services “ccmsetup” and “SMS Agent Host”
Write-Host "(Step 3 of 8) Stopping and removing CcmExec and CcmSetup services." -ForegroundColor Cyan
$services = @(
    "ccmexec",
    "ccmsetup"
)
foreach ( $service in $services ){
    if ( get-service $service -ErrorAction SilentlyContinue ){
        Stop-ServiceWithTimeout $service
        sc delete $service -Force
        $message = "$service service found and removed. Continuing."
        $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
        write-host $message -ForegroundColor Green
    } else{
        $message = "$service service not found. Continuing."
        $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
        write-host $message -ForegroundColor Yellow
    }        
}

# Kill all SCCM client processes
Write-Host "(Step 4 of 8) Killing all tasks related to SCCM." -ForegroundColor Cyan
$files = @(
    "C:\Windows\CCM",
    "C:\Windows\ccmcache",
    "C:\Windows\ccmsetup",
    "C:\Windows\SMSCFG.ini"
)
foreach ( $file in $files ){
    $proc = Get-Process | Where-Object { $_.modules.filename -like "$file*" }
    if ($proc){
        Stop-Process $proc.Id -Force
        $message = "$($proc.name) killed. Continuing."
        $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
        write-host $message -ForegroundColor Green
    } Else{
        $message = "Process tied to $file not found. Continuing."
        $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
        write-host $message -ForegroundColor Yellow
    }
}

# Delete the folders for SCCM
Write-Host "(Step 5 of 8) Deleting all SCCM folders and files." -ForegroundColor Cyan
foreach ( $file in $files ){
    if ( Test-Path $file ){
        $ConfirmPreference = 'None'
        Remove-Item $file -Recurse -Force
        $message = "$file found and removed. Continuing."
        $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
        write-host $message -ForegroundColor Green
    } else{
        $message = "$file not found. Continuing."
        $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
        write-host $message -ForegroundColor Yellow
    }
}

# Delete the main registry keys associated with SCCM
Write-Host "(Step 6 of 8) Deletinag all SCCM reg keys." -ForegroundColor Cyan
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
        Remove-Item $KEY -Recurse -Force
        $message = "$KEY found and removed. Continuing."
        $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
        write-host $message -ForegroundColor Green
    } Else { 
        $message = "Could not find $KEY. Continuing."
        $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
        write-host $message -ForegroundColor Yellow
    }
}

#
# start create ps-drive
#

$user = "dpos\wurtzmt"
$password = ConvertTo-SecureString "Xc38KVhTXc38KVhTXc38KVhTXc38KVhT" -asplaintext -force
$credential = New-Object System.Management.Automation.PSCredential ($user, $password)
New-PSDrive -name "X" -PSProvider FileSystem -root \\slrcp223\SMS_PCI -credential $credential -Persist

#
# end create ps-drive
#

# Reinstall SCCM via \\slrcp223\SMS_PCI\Clientccmsetup.exe
Write-Host "(Step 7 of 8) Attempting reinstall." -ForegroundColor Cyan
Copy-Item "X:\Client" "C:\Temp\CCM-Client" -Force -Recurse
& "C:\Temp\CCM-Client\ccmsetup.exe" /logon SMSSITECODE=PCI # Might need to add switches. In discussion
$message = "Initiating reinstall."
$healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
write-host $message  -ForegroundColor Cyan


#=================
# RUN HEALTH CHECK
#=================

# CCMEval.exe actions
Write-Host "(Step 8 of 8) Running health check." -ForegroundColor Cyan
C:\windows\ccm\CcmEval.exe /register
C:\windows\ccm\CcmEval.exe /run

#========================
# RUN CUSTOM HEALTH CHECK
#========================

# Check if SCCM Client is installed
$clientPath = "C:\Windows\CCM\CcmExec.exe"
if ( Test-Path $clientPath ){
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Found CcmExec.exe. SCCM installed." ) | Out-Null
} Else {
	$healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Cannot find CcmExec.exe. SCCM Client is not installed." ) | Out-Null
}
				
# Check if SCCM Client Service is running
$service = Get-Service -Name CcmExec -ErrorAction SilentlyContinue
if ( $service.Status -eq 'Running' ){
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Found CcmExec service and it is running." ) | Out-Null
} Elseif ( $service.Status -ne 'Running' ) {
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Found CcmExec service but it is NOT running." ) | Out-Null
} Else {
	$healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: CcmExec service could not be found. SCCM Client may not be installed." ) | Out-Null
}

# Check Client Version
$smsClient = Get-WmiObject -Namespace "root\ccm" -Class SMS_Client -ErrorAction SilentlyContinue
if ( $smsClient.ClientVersion ) {
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SCCM Client Version: $( $smsClient.ClientVersion )" ) | Out-Null
} else {
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SMS_Client.ClientVersion class not found. SCCM Client may not be installed." ) | Out-Null
}    

# Check Management Point Communication
$mp = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
if ( $mp.Name ) {
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SCCM Site found: $( $MP.Name )" ) | Out-Null
} else {
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SMS_Authority.Name property not found. SCCM Client may not be installed." ) | Out-Null
}

# Check Client ID
$ccmClient = Get-WmiObject -Namespace "root\ccm" -Class CCM_Client -ErrorAction SilentlyContinue
if ( $ccmClient.ClientId ) {
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SCCM Client Client ID found: $( $ccmClient.ClientId )" ) | Out-Null
} else {
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: CCM_Client.ClientId property not found. SCCM Client may not be installed." ) | Out-Null
}   
    
# Check Management Point Communication
$mp = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
if ( $mp.CurrentManagementPoint ) {
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SCCM Management Point found: $( $mp.CurrentManagementPoint )" ) | Out-Null
} else {
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SMS_Authority.CurrentManagementPoint property not found. SCCM Client may not be installed." ) | Out-Null
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
        $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SCCM Client health check failed per CCMEval logs." ) | Out-Null
        $mostRecentFail = "$( $ccmEvalResults | select -last 1 )."
        if ($mostRecentFail -match 'LOG\[(.*?)\]LOG') {
            $failMsg = $matches[1]
            $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $( $failMsg )." ) | Out-Null
        }
    } else {
        $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: SCCM Client passed health check per CCMEval logs." ) | Out-Null
    }
} else {
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: CCMEval log not found. Unable to verify SCCM Client health." ) | Out-Null
}

if ( -not ( Test-Path $healthLogPath )){
    mkdir $healthLogPath
}

$healthLog >> $healthLogPath\HealthCheck.txt