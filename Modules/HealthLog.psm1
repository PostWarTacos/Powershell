function Append-HealthLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$path,

        [Parameter(Mandatory)]
        [string]$message,

        [Parameter()]
        [switch]$writeHost,

        [Parameter()]
        [string]$color,

        [Parameter()]
        [switch]$return
    )

    $healthLog = [System.Collections.ArrayList]@()

    $healthLog.Add("[$(Get-Date -Format 'dd-MMM-yy HH:mm:ss')] Message: $message") | Out-Null

    if ($PSBoundParameters.ContainsKey('WriteHost')) {
        if ($PSBoundParameters.ContainsKey('Color')) {
            Write-Host $message -ForegroundColor $color
        } else {
            Write-Host $message
        }
    }

    if ($PSBoundParameters.ContainsKey('Return')) {
        $null = return $message
    }
}

Export-ModuleMember -Function Append-HealthLog