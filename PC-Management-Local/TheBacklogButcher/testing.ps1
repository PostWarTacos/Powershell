# Define registry paths for installed applications
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

# Function to search for a Steam game uninstall string by AppID or Name
function Get-SteamGameUninstallString {
    param (
        [string]$GameName
    )

    foreach ($path in $uninstallPaths) {
        # Get all subkeys (installed apps)
        $apps = Get-ChildItem -Path $path -ErrorAction SilentlyContinue

        foreach ($app in $apps) {
            $displayName = (Get-ItemProperty -Path $app.PSPath -Name "DisplayName" -ErrorAction SilentlyContinue).DisplayName
            $uninstallString = (Get-ItemProperty -Path $app.PSPath -Name "UninstallString" -ErrorAction SilentlyContinue).UninstallString

            # Check if the game name matches
            if ($displayName -like "*$GameName*") {
                [PSCustomObject]@{
                    Name            = $displayName
                    UninstallString = $uninstallString
                    RegistryPath    = $app.PSPath
                }
            }
        }
    }
}

# Example Usage: Find a game's uninstall string
$game = "Portal"  # Change to your desired game
Get-SteamGameUninstallString -GameName $game
