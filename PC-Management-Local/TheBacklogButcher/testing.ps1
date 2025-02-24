Clear-Host
# Variables
$cutoffDate = ( Get-Date ).AddMonths( -6 )
# Define your Steam library path (adjust if you have multiple libraries)
$steamLibraryPath = "G:\SteamLibrary\steamapps"
$steamGames = [System.Collections.ArrayList]@()



Write-Host "Processing Steam games..."

# Retrieve all manifest files for installed games
$manifestFiles = Get-ChildItem -Path $steamLibraryPath -Filter "appmanifest_*.acf"

foreach ( $file in $manifestFiles ) {
    # Read the entire file content
    $content = Get-Content $file.FullName -Raw
    
    # Extract the AppID using a regex pattern
    if ( $content -match '"appid"\s+"(\d+)"' ) {
        $appId = $matches[1]
    }
    
    # Extract the game name using a regex pattern
    if ( $content -match '"name"\s+"([^"]+)"' ) {
        $name = $matches[1]
    }

    Clear-Variable lastPlayed
    # Extract the LastPlayed value using a regex pattern
    if ( $content -match '"LastPlayed"\s+"([^"]+)"' ) {
        $unixTimestamp = $matches[1]
        # Convert the Unix timestamp to a DateTime object
        If ( $unixTimestamp -ne 0 ){
            $lastPlayed = [System.DateTimeOffset]::FromUnixTimeSeconds( $unixTimestamp ).DateTime
        }
    }

    $installDate = Get-ChildItem -Path $file.FullName |
        Select-Object -ExpandProperty CreationTime

    If ( $lastPlayed -lt $cutoffDate -and $installDate -lt $cutoffDate ){
        $steamGames.add( [PSCustomObject]@{ Name=$name; LastPlayed=$lastPlayed; InstallDate=$installDate; UninstallString="steam://uninstall/$appId" }) | Out-Null
    }
}   
# ---------------------------------------------------------------------------------------------
 foreach ( $game in $steamGames ) {
    Write-Host "Uninstalling Steam game $( $game.Name )  " -ForegroundColor Yellow -NoNewline
    Write-Host "Install Date: $( $game.InstallDate )  " -ForegroundColor Cyan -NoNewline
    Write-Host "Last played: $( $game.LastPlayed )" -ForegroundColor Green
    #Invoke-UninstallGame -UninstallString $game.UninstallString
}
