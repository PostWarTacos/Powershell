# ------------------- FUNCTIONS -------------------- #

function Stop-ServiceWithTimeout {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServiceName,

        [int]$TimeoutSeconds = 30
    )

    Write-Host "Attempting to stop service: $ServiceName" -ForegroundColor Yellow
    
    # Attempt to stop if service is running
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ( $service.Status -eq 'Running' ){
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue | Out-Null
    }
    
    $elapsed = 0
    while ( $elapsed -lt $TimeoutSeconds ) {
        Start-Sleep -Seconds 1
        $elapsed++

        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($null -eq $service -or $service.Status -eq 'Stopped') {
            Write-Host "Service $ServiceName stopped successfully." -ForegroundColor Green
            Start-Sleep -Seconds 2 # Small delay to ensure processes finish
            break
        }
    }
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ( $null -eq $service -or $service.Status -eq 'Stopped' ) {
        # do nothing
    }
    else {
        # If the service is still running after the timeout, force kill the process
        Write-Host "Timeout reached! Forcefully terminating the service process." -ForegroundColor Green
        $serviceProcess = Get-CimInstance -ClassName Win32_Service | Where-Object { $_.Name -eq $ServiceName }
        if ( $serviceProcess -and $serviceProcess.ProcessId -ne 0 ) {
            Stop-Process -Id $serviceProcess.ProcessId -Force -ErrorAction SilentlyContinue
            Write-Host "Service process terminated." -ForegroundColor Green
        } else {
            Write-Host "Service was already stopped or process not found." -ForegroundColor Yellow
        }
    }
}

function Update-HealthLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [switch]$WriteHost,

        [Parameter()]
        [string]$Color,

        [Parameter()]
        [switch]$Return
    )

    $healthLog.Add("[$(Get-Date -Format 'dd-MMM-yy HH:mm:ss')] Message: $message") | Out-Null

    if ( $PSBoundParameters.ContainsKey('WriteHost') -and $PSBoundParameters.ContainsKey('Color') ) {
        Write-Host $message -ForegroundColor $Color
    }
    else {
        Write-Host $Message
    }

    if ($PSBoundParameters.ContainsKey('Return')) {
        $null = return $message | Out-Null
    }
}

function Run-HealthCheck {

    $allPassed = $true

    # Check if SCCM Client is installed
    if ( Test-Path "C:\Windows\CCM\CcmExec.exe" ) {
        Update-HealthLog -path $healthLogPath -message "Found CcmExec.exe. SCCM installed." -WriteHost -color Green
    } else {
        Update-HealthLog -path $healthLogPath -message "Cannot find CcmExec.exe." -WriteHost -color Red
        $allPassed = $false
    }

    # Check if SCCM Client Service is running
    $service = Get-Service -Name CcmExec -ErrorAction SilentlyContinue
    if ( $service.Status -eq 'Running' ) {
        Update-HealthLog -path $healthLogPath -message "Found CcmExec service and it is running." -WriteHost -color Green
    } elseif ( $service.Status -ne 'Running' ) {
        Update-HealthLog -path $healthLogPath -message "Found CcmExec service but it is NOT running." -WriteHost -color Red
        $allPassed = $false
    } else {
        Update-HealthLog -path $healthLogPath -message "CcmExec service could not be found." -WriteHost -color Red
        $allPassed = $false
    }

    # Check Client Version
    $smsClient = Get-CimInstance -Namespace "root\ccm" -ClassName SMS_Client -ErrorAction SilentlyContinue
    if ( $smsClient.ClientVersion ) {
        Update-HealthLog -path $healthLogPath -message "SCCM Client Version: $($smsClient.ClientVersion)" -WriteHost -color Green
    } else {
        Update-HealthLog -path $healthLogPath -message "Client Version not found." -WriteHost -color Red
        $allPassed = $false
    }

    # Check Management Point Site Name
    $mp = Get-CimInstance -Namespace "root\ccm" -ClassName SMS_Authority -ErrorAction SilentlyContinue
    if ( $mp.Name ) {
        Update-HealthLog -path $healthLogPath -message "SCCM Site found: $($mp.Name)" -WriteHost -color Green
    } else {
        Update-HealthLog -path $healthLogPath -message "SMS_Authority.Name property not found." -WriteHost -color Red
        $allPassed = $false
    }

    # Check Client ID
    $ccmClient = Get-CimInstance -Namespace "root\ccm" -ClassName CCM_Client -ErrorAction SilentlyContinue
    if ( $ccmClient.ClientId ) {
        Update-HealthLog -path $healthLogPath -message "SCCM Client Client ID found: $($ccmClient.ClientId)" -WriteHost -color Green
    } else {
        Update-HealthLog -path $healthLogPath -message "Client Id property not found." -WriteHost -color Red
        $allPassed = $false
    }

    # Check Management Point FQDN
    if ( $mp.CurrentManagementPoint ) {
        Update-HealthLog -path $healthLogPath -message "SCCM Management Point found: $($mp.CurrentManagementPoint)" -WriteHost -color Green
    } else {
        Update-HealthLog -path $healthLogPath -message "Management Point property not found." -WriteHost -color Red
        $allPassed = $false
    }

    return $allPassed
}

# ------------------- VARIABLES -------------------- #

# Creates an Arraylist which is mutable and easier to manipulate than an array.
$healthLog = [System.Collections.ArrayList]@()

# Error handling
$errorCount = 0
$critErrors = $false

# Used in final health check
$maxAttempts = 3
$success = $false

# Directories
$healthLogPath = "C:\drivers\ccm\logs"
$localInstallerPath = "C:\drivers\ccm\ccmsetup"

# Domain Specific Variables
#$serverInstallerPath = "\\slrcp223\SMS_PCI\Client" # PCI
#$serverInstallerPath = "\\scanz223\SMS_DDS\Client" # DDS

# ------------------- CREATE DIRECTORIES -------------------- #

# Check for directory for ccm logs used in this script
if ( -not ( Test-Path $healthLogPath )) {
    mkdir $healthLogPath | Out-Null
}

# ------------------- MAIN SCRIPT -------------------- #

Clear-Host

$message = "Attempting repair actions on $(hostname)"
Update-HealthLog -path $healthLogPath -Message $message -WriteHost -Color Cyan

# Remove certs and restart service
# Possible this is the only needed fix.
# Run this first step and then test if it worked before 
Write-Host "(Step 1 of 8) Stopping CcmExec to remove SMS certs." -ForegroundColor Cyan
$found = Get-Service CcmExec -ErrorAction SilentlyContinue
if ( $found ){
    try {
        Stop-ServiceWithTimeout CcmExec
        write-host "Removing SMS certs."  -ForegroundColor Yellow
        Get-ChildItem Cert:\LocalMachine\SMS | Remove-Item
        Start-Service CcmExec -ErrorAction SilentlyContinue
    
        # Start service
        Start-Sleep -Seconds 10 # Allow some time for the service to start
    
        # Attempt to contact MP and pull new policy. If this works, client should be healthy.
        Invoke-WmiMethod -Namespace "root\ccm" -Class "SMS_Client" -Name "TriggerSchedule" -ArgumentList "{00000000-0000-0000-0000-000000000021}" | Out-Null
        $policyAgentLogs = "C:\Windows\CCM\Logs\PolicyAgent.log"
        $recentLogs = Get-Content $policyAgentLogs -Tail 50
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
            Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Green
            exit 102
        } else {
            $message = "Failed to start service. Continuing with SCCM Client removal and reinstall."
            Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Red -return
        }   
    }
    catch {
           $message = "Failed to start service. Continuing with SCCM Client removal and reinstall."
            Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Red -return
    }
} Else {
    $message = "CcmExec Service not installed. Continuing with SCCM Client removal and reinstall."
    Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Yellow
}

# Clean uninstall
Write-Host "(Step 2 of 8) Performing SCCM uninstall." -ForegroundColor Cyan
if ( Test-Path C:\Windows\ccmsetup\ccmsetup.exe ){
    try {
        Get-Service -Name CcmExec -ErrorAction SilentlyContinue | Stop-Service -Force
        Get-Service -Name ccmsetup -ErrorAction SilentlyContinue | Stop-Service -Force
        $proc = Start-Process -FilePath "C:\Windows\ccmsetup\ccmsetup.exe" -ArgumentList "/uninstall" -PassThru -Verbose
        $proc.WaitForExit()
        if ( $proc.ExitCode -ne 0 ){
            throw "SCCM uninstall failed with exit code $($proc.exitcode)"
        }
        $message = "Ccmsetup.exe uninstalled."
        Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Green
    }
    catch {
        $message = "Failed to uninstall ccm. Exiting script. Caught error: $_"
        Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Red -return
        $critErrors = $true
        exit $_
    }
} else {
    $message = "Ccmsetup.exe not found."
    Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Yellow
}

# Remove both services “ccmsetup” and “SMS Agent Host”
Write-Host "(Step 3 of 8) Stopping and removing CcmExec and CcmSetup services." -ForegroundColor Cyan
$services = @(
    "ccmexec",
    "ccmsetup"
)
foreach ( $service in $services ){
    if ( get-service $service -ErrorAction SilentlyContinue ){
        try {
            Stop-ServiceWithTimeout $service
            sc delete $service -Force -ErrorAction SilentlyContinue
            $message = "$service service found and removed."
            Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Green   
        }
        catch {
            $message = "Failed to stop and remove $service service. Continuing script but may cause issues."
            Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Red -return
            $errorCount++
        }
    } else{
        $message = "$service service not found."
        Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Yellow
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
        try {
            Stop-Process $proc.Id -Force -ErrorAction SilentlyContinue
            $message = "$($proc.name) killed. Process was tied to $file."
            Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Green    
        }
        catch {
            $message = "Failed to kill $proc process. Continuing script but may cause issues."
            Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Red -return
            $errorCount++
        }
    } Else{
        $message = "Process tied to $file not found."
        Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Yellow
    }
}

# Delete the folders for SCCM
Write-Host "(Step 5 of 8) Deleting all SCCM folders and files." -ForegroundColor Cyan
foreach ( $file in $files ){
    if ( Test-Path $file ){
        try {
            $null = takeown /F $file /R /A /D Y 2>&1
            $ConfirmPreference = 'None'
            Remove-Item $file -Recurse -Force -ErrorAction SilentlyContinue
            $message = "$file found and removed."
            Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Green    
        }
        catch {
            $message = "Failed to remove $file file(s). Continuing script but may cause issues."
            Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Red -return
            $errorCount++
        }
    } else{
        $message = "$file not found."
        Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Yellow
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
    "HKLM:\System\CurrentControlSet\Services\ccmsetup",
    "HKLM:\System\CurrentControlSet\Services\eventlog\Application\Configuration Manager Agent",
    "HKLM:\Software\Microsoft\SystemCertificates\SMS\Certificates\*"
)
foreach ( $key in $keys ){
    if( Test-Path $KEY ){
        try {
            Remove-Item $KEY -Recurse -Force -ErrorAction SilentlyContinue
            $message = "$KEY found and removed."
            Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Green
        }
        catch {
            $message = "Failed to remove $key reg key. Continuing script but may cause issues."
            Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Red -return
            $errorCount++
        }
    } Else { 
        $message = "Could not find $KEY."
        Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Yellow
    }
}

# Remove SCCM namespaces from WMI repository
Write-Host "(Step 7 of 8) Remove SCCM namespaces from WMI repo." -ForegroundColor Cyan
try {
    Get-CimInstance -Query "Select * From __Namespace Where Name='CCM'" -Namespace "root" -ErrorAction SilentlyContinue | Remove-CimInstance -Verbose -Confirm:$false -ErrorAction SilentlyContinue
    Get-CimInstance -Query "Select * From __Namespace Where Name='CCMVDI'" -Namespace "root" -ErrorAction SilentlyContinue | Remove-CimInstance -Verbose -Confirm:$false -ErrorAction SilentlyContinue
    Get-CimInstance -Query "Select * From __Namespace Where Name='SmsDm'" -Namespace "root" -ErrorAction SilentlyContinue | Remove-CimInstance -Verbose -Confirm:$false -ErrorAction SilentlyContinue
    Get-CimInstance -Query "Select * From __Namespace Where Name='sms'" -Namespace "root\cimv2" -ErrorAction SilentlyContinue | Remove-CimInstance -Verbose -Confirm:$false -ErrorAction SilentlyContinue
    $message = "Namespace(s) found and removed."
    Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Green
}
catch {
    $message = "Failed to remove namespace(s). Continuing script but may cause issues."
    Update-HealthLog -path $healthLogPath -message $message -WriteHost -color Red -return
    $errorCount++
}

if ( $errorCount -gt 0 ){
    $continue = Read-Host "There were $errorCount non-critical errors. Do you wish to continue with the reinstall? There's no guarantee it will succeed. (y/n)"
    if( $continue -eq "y" ){
        # Do nothing
    }
    elseif( $continue -eq "n" ){
        exit 101
    }
}

$healthLog >> $healthLogPath\HealthCheck.txt