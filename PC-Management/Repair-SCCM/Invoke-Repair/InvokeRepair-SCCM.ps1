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
$message = "Attempting repair actions."
$healthLogPath = "C:\drivers\CCM\Logs\"
If( -not ( Test-Path $healthLogPath )) {
    mkdir $healthLogPath
}
"[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message" >> "$healthLogPath\HealthCheck.txt" 
write-host $message

# Remove certs and restart service
# Possible this is the only needed fix.
# Run this first step and then test if it worked before continuing. 
Write-Host "(Step 1 of 7) Stopping CcmExec to remove SMS certs." -ForegroundColor Yellow
$found = Get-Service CcmExec -ErrorAction SilentlyContinue | where status -ne "stopped"
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
        $message = "Service restarted successfully and MP contacted."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message Ending actions on current target." >> "$healthLogPath\HealthCheck.txt" 
        #$sessionId = $PSSession.Id
        $psSenderInfo = $( $EXECUTIONCONTEXT.SessionState.PSVariable.GetValue( "PSSenderInfo" ))
        if ( $psSenderInfo ) {
            Remove-PSSession -Id $psSenderInfo.SessionId
        }
        write-host $message -ForegroundColor Green
    } else {
        $message = "Failed to start service. Continuing with SCCM Client repair."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message" >> "$healthLogPath\HealthCheck.txt"
        write-host $message -ForegroundColor Red
    }
} Else {
    $message = "CcmExec Service not installed."
    "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message" >> "$healthLogPath\HealthCheck.txt" 
    write-host $message -ForegroundColor Red
}

# Clean uninstall
Write-Host "(Step 2 of 7) Performing complete clean uninstall." -ForegroundColor Yellow
if ( Test-Path C:\Windows\ccmsetup\ccmsetup.exe ){
    C:\Windows\ccmsetup\ccmsetup.exe /uninstall
    $message = "Ccmsetup.exe uninstalled. Continuing."
    "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message" >> "$healthLogPath\HealthCheck.txt" 
    write-host $message -ForegroundColor Green
} else {
    $message = "Ccmsetup.exe not found. Continuing."
    "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message" >> "$healthLogPath\HealthCheck.txt" 
    write-host $message -ForegroundColor Red
}

# Remove both services “ccmsetup” and “SMS Agent Host”
Write-Host "(Step 3 of 7) Stopping and removing CcmExec and CcmSetup services." -ForegroundColor Yellow
$services = @(
    "ccmexec",
    "ccmsetup"
)
foreach ( $service in $services ){
    if ( get-service $service -ErrorAction SilentlyContinue ){
        Stop-ServiceWithTimeout $service
        sc delete $service -Force
        $message = "$service service found and removed. Continuing."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message" >> "$healthLogPath\HealthCheck.txt"
        write-host $message -ForegroundColor Green
    } else{
        $message = "$service service not found. Continuing."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message" >> "$healthLogPath\HealthCheck.txt"
        write-host $message -ForegroundColor Red
    }        
}

# Kill all SCCM client processes
Write-Host "(Step 4 of 7) Killing all tasks related to SCCM." -ForegroundColor Yellow
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
        $message = "$proc.name killed. Continuing."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message" >> "$healthLogPath\HealthCheck.txt" 
        write-host $message -ForegroundColor Green
    } Else{
        $message = "$proc.name not found. Continuing."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message" >> "$healthLogPath\HealthCheck.txt" 
        write-host $message -ForegroundColor Red
    }
}

# Delete the folders for SCCM
Write-Host "(Step 5 of 7) Deleting all SCCM folders and files." -ForegroundColor Yellow
foreach ( $file in $files ){
    if ( Test-Path $file ){
        Remove-Item $file -Recurse -Force
        $message = "$file found and removed. Continuing."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message" >> "$healthLogPath\HealthCheck.txt"
        write-host $message -ForegroundColor Green
    } else{
        $message = "$file not found. Continuing."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message" >> "$healthLogPath\HealthCheck.txt" 
        write-host $message -ForegroundColor Red
    }
}

# Delete the main registry keys associated with SCCM
Write-Host "(Step 6 of 7) Deletinag all SCCM reg keys." -ForegroundColor Yellow
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
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message" >> "$healthLogPath\HealthCheck.txt" 
        write-host $message -ForegroundColor Green
    } Else { 
        $message = "Could not find $KEY. Continuing."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message" >> "$healthLogPath\HealthCheck.txt" 
        write-host $message -ForegroundColor Red
    }
}

# Reinstall SCCM via \\slrcp223\SMS_PCI\Clientccmsetup.exe
Write-Host "(Step 7 of 7) Attempting reinstall." -ForegroundColor Yellow
& "\\slrcp223\SMS_PCI\Clientccmsetup.exe /logon SMSSITECODE=PCI" # Might need to add switches. In discussion
$message = "Initiating reinstall."
"[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message" >> "$healthLogPath\HealthCheck.txt" 
write-host $message  -ForegroundColor Cyan 