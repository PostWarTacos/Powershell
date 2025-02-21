# ."$env:userprofile\desktop\Change-VariableToUpper.ps1" THE '.' BEFORE "$" IS REQUIRED (dot-sourcing)
# Change-VariableToUpper -filepath "myscript.ps1"

function Change-VariableToUpper {
    param (
        [Parameter( Mandatory = $TRUE )]
        [string]$FILEPATH  # Path to the PowerShell script to process
    )

    if ( -not ( Test-Path $FILEPATH )) {
        Write-Host "File not found: $FILEPATH" -ForegroundColor Yellow
        return
    }

    # Read the script content
    $SCRIPTCONTENT = Get-Content $FILEPATH -Raw

    # Regex pattern to find PowerShell variables ($ followed by valid variable characters)
    $VARIABLEPATTERN = '\$[a-zA-Z_][a-zA-Z0-9_]*'

    # Find all variables in the script
    $ALLVARs = [regex]::Matches( $SCRIPTCONTENT, $VARIABLEPATTERN )

    # Create a dictionary to store original and transformed variable names
    $VARIABLEMAP = @{}

    foreach ( $VAR in $ALLVARS ) {
        $ORIGINALVAR = $MATCH.Value
        $UPPERVAR = '$' + ($ORIGINALVAR.Substring(1).ToUpper())  # Convert everything after $ to uppercase

        # Only replace if the variable name is not already uppercase
        if ( $ORIGINALVAR -cne $UPPERVAR ) {
            $VARIABLEMAP[$ORIGINALVAR] = $UPPERVAR
        }
    }

    # Replace all occurrences of found variables with uppercase versions
    foreach ( $KEY in $VARIABLEMAP.Keys ) {
        $SCRIPTCONTENT = $SCRIPTCONTENT -replace [regex]::Escape($KEY), $VARIABLEMAP[$KEY]
    }

    # Output the transformed script to a new file
    $NEWFILEPATH = $FILEPATH -replace '\.ps1$', '_UPPER.ps1'
    $SCRIPTCONTENT | Set-Content -Path $NEWFILEPATH

    Write-Host "Processed script saved as: $NEWFILEPATH" -ForegroundColor Green
}
