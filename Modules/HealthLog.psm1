function Append-HealthLog {
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

Export-ModuleMember -Function Append-HealthLog