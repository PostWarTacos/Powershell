function Create-HealthLog(){
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $path,

        [Parameter(Mandatory)]
        [string]
        $message,

        [Parameter()]
        [string]
        $writeHost,

        [Parameter()]
        [string]
        $color,

        [Parameter()]
        [string]
        $return
    )

    $healthLog = [System.Collections.ArrayList]@()
    $healthLogPath = $path
    If( -not ( Test-Path $healthLogPath )) {
        mkdir $healthLogPath
    }
    $healthLog.Add("[$(get-date -Format "dd-MMM-yy HH:mm:ss")] Message: $message") | Out-Null
    if ( $writeHost ){
        if ( $color ){
            write-host $message -ForegroundColor $color
        } else { write-host $message }
    }
    if ( $return ){
        $message
    }
}