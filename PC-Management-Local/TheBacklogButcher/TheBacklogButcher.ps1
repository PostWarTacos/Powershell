<#
#####################################################################################
Name    :   TheBacklogButcher.ps1
Purpose :   Will filter PC games from steam, gog, amazon, epic, etc.
    and then delete the games that haven't been played in the last 6 months
Created :   02/22/2025
Author  :   Matthew T Wurtz
#####################################################################################
#>

# Variables
$cutoffDate = (Get-Date).AddMonths(-6)
# Define your Steam library path (adjust if you have multiple libraries)
$steamLibraryPath = "G:\SteamLibrary\steamapps"
$steamGames = [System.Collections.ArrayList]@()

function Invoke-UninstallGame { # Function to invoke an uninstall command.
    param (
        [Parameter(Mandatory=$true)]
        [string]$UninstallString
    )
    Write-Host "Executing uninstall command: $UninstallString"
    try {
        # This example uses cmd.exe to run the uninstall command. 
        # Adjust the command execution as needed for your environment.
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $UninstallString" -Verb RunAs -Wait
    }
    catch {
        Write-Error "Failed to uninstall game using command: $UninstallString"
    }
}

function Filter-SteamGames { # Function to filter and uninstall Steam games
    Write-Host "Processing Steam games..."

    # Retrieve all manifest files for installed games
    $manifestFiles = Get-ChildItem -Path $steamLibraryPath -Filter "appmanifest_*.acf"

    foreach ($file in $manifestFiles) {
        # Read the entire file content
        $content = Get-Content $file.FullName -Raw
        
        # Extract the AppID using a regex pattern
        if ($content -match '"appid"\s+"(\d+)"') {
            $appId = $matches[1]
        }
        
        # Extract the game name using a regex pattern
        if ($content -match '"name"\s+"([^"]+)"') {
            $name = $matches[1]
        }

        # Extract the LastPlayed value using a regex pattern
        if ($content -match '"LastPlayed"\s+"([^"]+)"') {
            $unixTimestamp = $matches[1]
            # Convert the Unix timestamp to a DateTime object
            If ( $unixTimestamp -ne 0 ){
                $lastPlayed = [System.DateTimeOffset]::FromUnixTimeSeconds($unixTimestamp).DateTime
            }
        }

        If ( $lastPlayed -lt $cutoffDate ){
            $steamGames.add([PSCustomObject]@{Name=$name; LastPlayed=$lastPlayed; UninstallString="steam://uninstall/$appId "})
        }
    }   
    # ---------------------------------------------------------------------------------------------
     foreach ($game in $steamGames) {
        Write-Host "Uninstalling Steam game '$($game.Name)' (Last played: $($game.LastPlayed))"
        Invoke-UninstallGame -UninstallString $game.UninstallString
    }
}

function Filter-GOGGames { # Function to filter and uninstall GOG games
    Write-Host "Processing GOG games..."
    # --- Replace the following placeholder data with your GOG Galaxy data retrieval logic ---
    $games = @(
        [PSCustomObject]@{Name="GOGGame1"; LastPlayed=(Get-Date).AddMonths(-8); UninstallString="C:\GOG Galaxy\uninstall.exe /uninstall GOGGame1"},
        [PSCustomObject]@{Name="GOGGame2"; LastPlayed=(Get-Date).AddMonths(-2); UninstallString="C:\GOG Galaxy\uninstall.exe /uninstall GOGGame2"}
    )
    # -------------------------------------------------------------------------------------------
    $oldGames = $games | Where-Object { $_.LastPlayed -lt $cutoffDate }
    foreach ($game in $oldGames) {
        Write-Host "Uninstalling GOG game '$($game.Name)' (Last played: $($game.LastPlayed))"
        Invoke-UninstallGame -UninstallString $game.UninstallString
    }
}

function Filter-AmazonGames { # Function to filter and uninstall Amazon games
    Write-Host "Processing Amazon games..."
    # --- Replace the following placeholder data with your Amazon Games retrieval logic ---
    $games = @(
        [PSCustomObject]@{Name="AmazonGame1"; LastPlayed=(Get-Date).AddMonths(-9); UninstallString="msiexec /x {GUID-AmazonGame1}"},
        [PSCustomObject]@{Name="AmazonGame2"; LastPlayed=(Get-Date).AddMonths(-1); UninstallString="msiexec /x {GUID-AmazonGame2}"}
    )
    # -----------------------------------------------------------------------------------------------
    $oldGames = $games | Where-Object { $_.LastPlayed -lt $cutoffDate }
    foreach ($game in $oldGames) {
        Write-Host "Uninstalling Amazon game '$($game.Name)' (Last played: $($game.LastPlayed))"
        Invoke-UninstallGame -UninstallString $game.UninstallString
    }
}

function Filter-EpicGames { # Function to filter and uninstall Epic games
    Write-Host "Processing Epic games..."
    # --- Replace the following placeholder data with your Epic Games data retrieval logic ---
    $games = @(
        [PSCustomObject]@{Name="EpicGame1"; LastPlayed=(Get-Date).AddMonths(-10); UninstallString="C:\Epic Games\Launcher\Portal\Binaries\UnrealEngineLauncher.exe /uninstall EpicGame1"},
        [PSCustomObject]@{Name="EpicGame2"; LastPlayed=(Get-Date).AddMonths(-3); UninstallString="C:\Epic Games\Launcher\Portal\Binaries\UnrealEngineLauncher.exe /uninstall EpicGame2"}
    )
    # ---------------------------------------------------------------------------------------------
    $oldGames = $games | Where-Object { $_.LastPlayed -lt $cutoffDate }
    foreach ($game in $oldGames) {
        Write-Host "Uninstalling Epic game '$($game.Name)' (Last played: $($game.LastPlayed))"
        Invoke-UninstallGame -UninstallString $game.UninstallString
    }
}

function Filter-EAGames { # Function to filter and uninstall EA games
    Write-Host "Processing EA games..."
    # --- Replace the following placeholder data with your EA (Origin/EA Desktop) retrieval logic ---
    $games = @(
        [PSCustomObject]@{Name="EA_Game1"; LastPlayed=(Get-Date).AddMonths(-7); UninstallString="C:\Program Files (x86)\Origin\Origin.exe /uninstall EA_Game1"},
        [PSCustomObject]@{Name="EA_Game2"; LastPlayed=(Get-Date).AddMonths(-2); UninstallString="C:\Program Files (x86)\Origin\Origin.exe /uninstall EA_Game2"}
    )
    # ---------------------------------------------------------------------------------------------
    $oldGames = $games | Where-Object { $_.LastPlayed -lt $cutoffDate }
    foreach ($game in $oldGames) {
        Write-Host "Uninstalling EA game '$($game.Name)' (Last played: $($game.LastPlayed))"
        Invoke-UninstallGame -UninstallString $game.UninstallString
    }
}

function Filter-UbisoftGames { # Function to filter and uninstall Ubisoft games
    Write-Host "Processing Ubisoft games..."
    # --- Replace the following placeholder data with your Ubisoft retrieval logic ---
    $games = @(
        [PSCustomObject]@{Name="UbisoftGame1"; LastPlayed=(Get-Date).AddMonths(-8); UninstallString="C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\uninstall.exe UbisoftGame1"},
        [PSCustomObject]@{Name="UbisoftGame2"; LastPlayed=(Get-Date).AddMonths(-3); UninstallString="C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\uninstall.exe UbisoftGame2"}
    )
    # ---------------------------------------------------------------------------------------------
    $oldGames = $games | Where-Object { $_.LastPlayed -lt $cutoffDate }
    foreach ($game in $oldGames) {
        Write-Host "Uninstalling Ubisoft game '$($game.Name)' (Last played: $($game.LastPlayed))"
        Invoke-UninstallGame -UninstallString $game.UninstallString
    }
}

# Main execution: run the filters for each launcher
Filter-SteamGames
Filter-GOGGames
Filter-AmazonGames
Filter-EpicGames
Filter-EAGames
Filter-UbisoftGames

Write-Host "Finished processing games. All games not played in the last 6 months have been scheduled for uninstallation."
