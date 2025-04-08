<#
#   Intent: Based on US AFCENT System Center Configuration Manger Current Branch (SCCM-CB)
#       guide to troubleshoot and repair SCCM clients
#   Date: 24-Feb-25
#   Author: Matthew Wurtz
#>

<# Repair-SCCM

1. Delete SMS certs and reload service. Test if fixed, end actions if it is.

2. Clean uninstall

3. Remove both services “ccmsetup” and “SMS Agent Host”

4. End all SCCM tasks

5. Delete the folders for SCCM

6. Delete the main registries associated with SCCM

7. Install from \\slrcp223\SMS_PCI\Client\ccmsetup.exe

8. Manually reinstall

#>

#-------------------FUNCTIONS--------------------#

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

    $healthLog = [System.Collections.ArrayList]@()

    $healthLog.Add("[$(Get-Date -Format 'dd-MMM-yy HH:mm:ss')] Message: $message") | Out-Null

    if ( $PSBoundParameters.ContainsKey('WriteHost') -and $PSBoundParameters.ContainsKey('Color') ) {
        Write-Host $message -ForegroundColor $color
    }
    else {
        Write-Host $message
    }

    if ($PSBoundParameters.ContainsKey('Return')) {
        $null = return $message | Out-Null
    }
}

function Test-DirsMatch {
    param (
        [Parameter(Mandatory)]
        [string]$PathA,

        [Parameter(Mandatory)]
        [string]$PathB,

        [ValidateSet("MD5","SHA1","SHA256")]
        [string]$Algorithm = "SHA256"
    )

    $zipA = [System.IO.Path]::ChangeExtension((New-TemporaryFile).FullName, ".zip")
    $zipB = [System.IO.Path]::ChangeExtension((New-TemporaryFile).FullName, ".zip")
    
    try {
        Compress-Archive -Path "$PathA\*" -DestinationPath $zipA -Force -Verbose
        Compress-Archive -Path "$PathB\*" -DestinationPath $zipB -Force -Verbose

        $hashA = Get-FileHash -Path $zipA -Algorithm $Algorithm
        $hashB = Get-FileHash -Path $zipB -Algorithm $Algorithm

        return ( $hashA.Hash -eq $hashB.Hash )
    }
    finally {
        Remove-Item $zipA, $zipB -Force -ErrorAction SilentlyContinue
    }
}

function Find-ADSIObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    # Map LDAP filter
    $filter = "(&(objectClass=computer)(sAMAccountName=$Name`$))"

    $searcher = [ADSISearcher]::new($filter)
    $result = $searcher.FindOne()

    if ( $result -and $result.Properties["adspath"] ) {
        return [ADSI]$result.Properties["adspath"][0]
    } else {
        Write-Warning "'$Name' not found in AD."
        return $null
    }
}

#-------------------CREATE DIRECTORIES--------------------#

# Check for directory for ccm logs used in this script
$healthLogPath = "C:\drivers\ccm\logs"
if ( -not ( Test-Path $healthLogPath )) {
    mkdir $healthLogPath | Out-Null
}


# Check for directory used to install CCM
$localInstallerPath = "C:\drivers\ccm\ccmsetup"
$serverInstallerPath = "\\slrcp223\SMS_PCI\Client"

<#
$updatedInstaller = Test-DirsMatch -PathA $serverInstallerPath -PathB $localInstallerPath

if ( -not ( $updatedInstaller )) {
    $message = "$localInstallerPath doesn't contain the requesite files"
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color Red
    # Add computer to AD security group
    $group = [ADSI]"LDAP://CN=POS_RepairIT,OU=POS_Groups,OU=Managed_e3_POS,DC=DPOS,DC=LOC"
    $computer =  Find-ADSIObject -Name $( hostname )
    $group.Add( $computer.adspath )
    exit
}
Else { # Dirs match. Continue with repair.
    $message = "$localInstallerPath contains requesite files. Continuing install."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color Green
}
#>

#-------------------MAIN SCRIPT--------------------#

Clear-Host

# Creates an Arraylist which is mutable and easier to manipulate than an array.
$message = "Attempting repair actions."
Update-HealthLog -path $healthLogPath -message $message -writeHost -color Cyan -return

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
    Invoke-WmiMethod -Namespace "root\ccm" -Class "SMS_Client" -Name "TriggerSchedule" -ArgumentList "{00000000-0000-0000-0000-000000000021}" | Out-Null
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
        Update-HealthLog -path $healthLogPath -message $message -writeHost -color Green -return
        exit
    } else {
        $message = "Failed to start service. Continuing with SCCM Client repair."
        Update-HealthLog -path $healthLogPath -message $message -writeHost -color Yellow -return
    }
} Else {
    $message = "CcmExec Service not installed. Continuing with SCCM Client repair."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color Yellow -return
}

# Clean uninstall
Write-Host "(Step 2 of 8) Performing complete clean uninstall." -ForegroundColor Cyan
if ( Test-Path C:\Windows\ccmsetup\ccmsetup.exe ){
    $message = "Ccmsetup.exe uninstalled. Continuing."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color Green -return
    Start-Process -FilePath "C:\Windows\ccmsetup\ccmsetup.exe" -ArgumentList "/uninstall" -Wait -Verbose
} else {
    $message = "Ccmsetup.exe not found. Continuing."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color Yellow -return
}

# Remove both services “ccmsetup” and “SMS Agent Host”
Write-Host "(Step 3 of 8) Stopping and removing CcmExec and CcmSetup services." -ForegroundColor Cyan
$services = @(
    "ccmexec",
    "ccmsetup"
)
foreach ( $service in $services ){
    if ( get-service $service -ErrorAction SilentlyContinue ){
        $message = "$service service found and removed. Continuing."
        Update-HealthLog -path $healthLogPath -message $message -writeHost -color Green -return        
        Stop-ServiceWithTimeout $service
        sc delete $service -Force -ErrorAction SilentlyContinue
    } else{
        $message = "$service service not found. Continuing."
        Update-HealthLog -path $healthLogPath -message $message -writeHost -color Yellow -return
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
        $message = "$($proc.name) killed. Continuing."
        Update-HealthLog -path $healthLogPath -message $message -writeHost -color Green -return
        Stop-Process $proc.Id -Force -ErrorAction SilentlyContinue
    } Else{
        $message = "Process tied to $file not found. Continuing."
        Update-HealthLog -path $healthLogPath -message $message -writeHost -color Yellow -return
    }
}

# Delete the folders for SCCM
Write-Host "(Step 5 of 8) Deleting all SCCM folders and files." -ForegroundColor Cyan
foreach ( $file in $files ){
    if ( Test-Path $file ){
        $message = "$file found and removed. Continuing."
        Update-HealthLog -path $healthLogPath -message $message -writeHost -color Green -return
        $ConfirmPreference = 'None'
        Remove-Item $file -Recurse -Force -ErrorAction SilentlyContinue
    } else{
        $message = "$file not found. Continuing."
        Update-HealthLog -path $healthLogPath -message $message -writeHost -color Yellow -return
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
        $message = "$KEY found and removed. Continuing."
        Update-HealthLog -path $healthLogPath -message $message -writeHost -color Green -return
        Remove-Item $KEY -Recurse -Force -ErrorAction SilentlyContinue
    } Else { 
        $message = "Could not find $KEY. Continuing."
        Update-HealthLog -path $healthLogPath -message $message -writeHost -color Yellow -return
    }
}

# Reinstall SCCM via \\slrcp223\SMS_PCI\Clientccmsetup.exe
Write-Host "(Step 7 of 8) Attempting reinstall." -ForegroundColor Cyan
try {
    $message = "Initiating reinstall."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color Cyan -return
    Start-Process -FilePath "$localInstallerPath\ccmsetup.exe" -ArgumentList "/logon SMSSITECODE=PCI"
    Update-HealthLog -path $healthLogPath -message "Waiting for service to be installed." -writeHost
}
Catch{
    $message = "Install failed."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color Red -return
}
while ( -not ( Get-Service "ccmexec" -ErrorAction SilentlyContinue )) {
    Start-Sleep -Seconds 120
}

Update-HealthLog -path $healthLogPath -message "Waiting for service to show running." -writeHost
while ( (Get-Service "ccmexec").Status -ne "Running") {
    Start-Sleep -Seconds 120
}

#--------------------RUN CcmEval CHECK--------------------#

# CCMEval.exe actions
Write-Host "(Step 8 of 8) Registering CcmEval. Running CcmEval check." -ForegroundColor Cyan
C:\windows\ccm\CcmEval.exe /register
C:\windows\ccm\CcmEval.exe /run

#--------------------WAIT 10 MINS--------------------#

Start-Sleep -Seconds 600

#--------------------RUN CUSTOM HEALTH CHECK--------------------#

# Check if SCCM Client is installed
$clientPath = "C:\Windows\CCM\CcmExec.exe"
if ( Test-Path $clientPath ){
    $message = "Found CcmExec.exe. SCCM installed."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color Green
} Else {
	$message = "Cannot find CcmExec.exe. SCCM Client is not installed."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color red
}
				
# Check if SCCM Client Service is running
$service = Get-Service -Name CcmExec -ErrorAction SilentlyContinue
if ( $service.Status -eq 'Running' ){
    $message = "Found CcmExec service and it is running."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color Green
} Elseif ( $service.Status -ne 'Running' ) {
    $message = "Found CcmExec service but it is NOT running."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color red
} Else {
    $message = "CcmExec service could not be found. SCCM Client may not be installed."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color red
}

# Check Client Version
$smsClient = Get-WmiObject -Namespace "root\ccm" -Class SMS_Client -ErrorAction SilentlyContinue
if ( $smsClient.ClientVersion ) {
    $message = "SCCM Client Version: $( $smsClient.ClientVersion )"
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color Green
} else {
    $message = "SMS_Client.ClientVersion class not found. SCCM Client may not be installed."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color red
}    

# Check Management Point Communication
$mp = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
if ( $mp.Name ) {
    $message = "SCCM Site found: $( $MP.Name )"
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color Green
} else {
    $message = "SMS_Authority.Name property not found. SCCM Client may not be installed."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color red
}

# Check Client ID
$ccmClient = Get-WmiObject -Namespace "root\ccm" -Class CCM_Client -ErrorAction SilentlyContinue
if ( $ccmClient.ClientId ) {
    $message = "SCCM Client Client ID found: $( $ccmClient.ClientId )"
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color Green
} else {
    $message = "CCM_Client.ClientId property not found. SCCM Client may not be installed."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color red
}   
    
# Check Management Point Communication
$mp = Get-WmiObject -Namespace "root\ccm" -Class SMS_Authority -ErrorAction SilentlyContinue
if ( $mp.CurrentManagementPoint ) {
    $message = "SCCM Management Point found: $( $mp.CurrentManagementPoint )"
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color Green
} else {
    $message = "SMS_Authority.CurrentManagementPoint property not found. SCCM Client may not be installed."
    Update-HealthLog -path $healthLogPath -message $message -writeHost -color red
}

$healthLog >> $healthLogPath\HealthCheck.txt