# Check for admin rights
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator. Exiting."
    exit
}

# Prompt for target computer
$TargetComputer = Read-Host "Enter the target computer name or IP"

# Prompt for process name
$ProcessName = Read-Host "Enter the process name to kill"

# Establish remote session
$Session = New-PSSession -ComputerName $TargetComputer

# Get process and child processes, then kill them
Invoke-Command -Session $Session -ScriptBlock {
    param($ProcessName)
    function Get-ChildProcesses {
        param($ParentId)
        $children = Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $ParentId }
        foreach ($child in $children) {
            Get-ChildProcesses -ParentId $child.ProcessId
            Stop-Process -Id $child.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }
    $procs = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    foreach ($proc in $procs) {
        Get-ChildProcesses -ParentId $proc.Id
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
    # Delete PowerShell logs (requires admin)
    Remove-Item -Path "$env:windir\System32\winevt\Logs\Windows PowerShell.evtx" -Force -ErrorAction SilentlyContinue
    # Delete transcript files (if any)
    $transcriptPath = "$env:USERPROFILE\Documents\PowerShell_transcript*"
    Remove-Item -Path $transcriptPath -Force -ErrorAction SilentlyContinue
} -ArgumentList $ProcessName

# Remove remote session
Remove-PSSession $Session

# Delete local transcript files
$localTranscriptPath = "$env:USERPROFILE\Documents\PowerShell_transcript*"
Remove-Item -Path $localTranscriptPath -Force -ErrorAction SilentlyContinue

Write-Host "Operation complete."
