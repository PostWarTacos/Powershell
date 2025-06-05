function Add-HealthLog {
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

    $healthLog.Add("[$(Get-Date -Format 'dd-MMM-yy HH:mm:ss')] Message: $Message") | Out-Null

    if ($PSBoundParameters.ContainsKey('WriteHost')) {
        if ($PSBoundParameters.ContainsKey('Color')) {
            Write-Host $Message -ForegroundColor $Color
        } else {
            Write-Host $Message
        }
    }

    if ($PSBoundParameters.ContainsKey('Return')) {
        $null = return $Message
    }
}

function Invoke-Script(){
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$ComputerName,
        
        [Parameter(Mandatory)]
        [String]$FilePath
    )

    $transcriptLogPath = "C:\temp\logs"
    $udate = [int](get-date -UFormat %s)
    $fileName = [System.io.path]::GetFileNameWithoutExtension($FilePath)
    $fullPath = "$transcriptLogPath\$($fileName)_$($udate).txt"

    if ( -not ( Test-Path $transcriptLogPath )) {
        mkdir $transcriptLogPath | Out-Null
    }

    Start-Transcript -Path $fullPath

    $session = New-PSSession -ComputerName $ComputerName

    # Execute it remotely
    #Invoke-Command -Session $session -FilePath $FilePath
    $exitCode = Invoke-Command -Session $session -ScriptBlock {
        & using:$FilePath
        return $LASTEXITCODE
    }

    # Clean up session
    Remove-PSSession $session

    Stop-Transcript

    return $exitCode
}

Export-ModuleMember Add-HealthLog, Invoke-Script