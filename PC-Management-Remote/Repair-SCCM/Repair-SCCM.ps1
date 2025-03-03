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
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue

    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        Start-Sleep -Seconds 1
        $elapsed++

        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($null -eq $service -or $service.Status -eq 'Stopped') {
            Write-Host "Service $ServiceName stopped successfully."
        }

        Write-Host "Waiting for service to stop... ($elapsed/$TimeoutSeconds)"
    }

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


Clear-Host

# Creates an Arraylist which is mutable and easier to manipulate than an array.
$healthLogPath = "C:\drivers\CCM\Logs\"
"[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $($_)" >> "$healthLogPath\HealthCheck.txt" 
"[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Attempting repair actions." >> "$healthLogPath\HealthCheck.txt" 
Write-Host "Running all repair actions..."

# Remove certs and restart service
# Possible this is the only needed fix.
# Run this first step and then test if it worked before continuing. 
Write-Host "(Step 1 of 6) Stopping CcmExec to remove SMS certs." -ForegroundColor Yellow
$found = Get-Service CcmExec -ErrorAction SilentlyContinue
if ( $found ){
    Stop-ServiceWithTimeout CcmExec
    do {
        Start-Sleep -Seconds 3
        $service = Get-Service -Name CcmExec
    } while ($_.Status -ne 'Stopped')
    Get-ChildItem Cert:\LocalMachine\SMS | Remove-Item
    Start-Service CcmExec -ErrorAction SilentlyContinue

    # Start service
    Start-Sleep -Seconds 5  # Allow some time for the service to start

    # Attempt to contact MP and pull new policy. If this works, client should be healthy.
    $policyUpdate = Invoke-WmiMethod -Namespace "root\ccm" -Class "SMS_Client" -Name "TriggerSchedule"
        -ArgumentList "{00000000-0000-0000-0000-000000000021}"
    $logPath = "C:\Windows\CCM\Logs\PolicyAgent.log"
    $recentLogs = Get-Content $logPath -Tail 50
    $success = $recentLogs | Select-String -Pattern "Updated namespace .* successfully|`
        Successfully received policy assignments from MP|PolicyAgent successfully processed the policy assignment|`
        Completed policy evaluation cycle"

    # Announce success/fail
    if ( $success ) {
        Write-Host "Service restarted successfully. Manually check if issue is resolved. Ending actions on current target." -ForegroundColor Yellow
        Write-Host "Disconnecting from current session and moving to the next target." -ForegroundColor Yellow
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Service restarted successfully. Manually check if issue is resolved. Ending actions on current target." >> "$healthLogPath\HealthCheck.txt" 
        #$sessionId = $PSSession.Id
        $psSenderInfo = $( $EXECUTIONCONTEXT.SessionState.PSVariable.GetValue( "PSSenderInfo" ))
        if ( $psSenderInfo ) {
            Remove-PSSession -Id $psSenderInfo.SessionId
        }
        return
    } else {
        Write-Host "Failed to start service. Continuing with SCCM Client repair." -ForegroundColor Yellow
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Failed to start service. Continuing with SCCM Client repair." >> "$healthLogPath\HealthCheck.txt" 
    }
} Else {
    Write-Host "CcmExec Service not installed."
    "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: CcmExec Service not installed." >> "$healthLogPath\HealthCheck.txt" 
}

# Clean uninstall
Write-Host "(Step 2 of 6) Performing complete clean uninstall." -ForegroundColor Yellow
if ( Test-Path C:\Windows\ccmsetup\ccmsetup.exe ){
    C:\Windows\ccmsetup\ccmsetup.exe /uninstall
    Write-Host "Ccmsetup.exe uninstalled. Continuing."
    "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Ccmsetup.exe uninstalled. Continuing." >> "$healthLogPath\HealthCheck.txt" 
} else {
    Write-Host "Ccmsetup.exe not found. Continuing."
    "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Ccmsetup.exe not found. Continuing." >> "$healthLogPath\HealthCheck.txt" 
}

# Remove both services “ccmsetup” and “SMS Agent Host”
Write-Host "(Step 3 of 6) Stopping and removing CcmExec and CcmSetup services." -ForegroundColor Yellow
$services = @(
    "ccmexec",
    "ccmsetup"
)
foreach ( $service in $services ){
    if (get-service $service){
        Stop-ServiceWithTimeout $service
        sc delete $service -Force
        Write-Host "$service service found and removed. Continuing."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $service service found and removed. Continuing." >> "$healthLogPath\HealthCheck.txt" 
    } else{
        Write-Host "$service service not found. Continuing."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $service service not found. Continuing." >> "$healthLogPath\HealthCheck.txt" 
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
        Write-Host "$file found and removed. Continuing."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $file found and removed. Continuing." >> "$healthLogPath\HealthCheck.txt" 
    } else{
        Write-Host "$file not found. Continuing."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $file not found. Continuing." >> "$healthLogPath\HealthCheck.txt" 
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
        Write-Host "$KEY found and removed. Continuing."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $KEY found and removed. Continuing." >> "$healthLogPath\HealthCheck.txt" 
    } Else { 
        Write-Host "Could not find $KEY. Continuing."
        "[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $KEY not found. Continuing." >> "$healthLogPath\HealthCheck.txt" 
    }
}

# Reinstall SCCM via \\slrcp223\SMS_PCI\Clientccmsetup.exe
Write-Host "(Step 6 of 6) Attempting reinstall." -ForegroundColor Yellow
& "\\slrcp223\SMS_PCI\Clientccmsetup.exe /logon SMSSITECODE=PCI" # Might need to add switches. In discussion
"[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: Initiating reinstall." >> "$healthLogPath\HealthCheck.txt" 

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