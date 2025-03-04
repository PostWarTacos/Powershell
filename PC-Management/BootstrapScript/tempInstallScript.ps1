$install = @("AgileBits.1Password"
"Corsair.iCUE.5"
"Git.Git"
"JanDeDobbeleer.OhMyPosh"
"Microsoft.WindowsTerminal"
"Notion.Notion"
"Spotify.Spotify"
"Microsoft.Sysinternals"
"VSCodium.VSCodium"
"7zip.7zip"
"Brave.Brave"
"EpicGames.EpicGamesLauncher"
"GIMP.GIMP"
"Insecure.Nmap"
"Mozilla.Thunderbird"
"Oracle.VirtualBox"
"PrivateInternetAccess.PrivateInternetAccess"
"RevoUninstaller.RevoUninstaller"
"SteelSeries.GG"
"Valve.Steam")

$found =  $null

foreach ( $app in $install ){
    $found = winget list --id=$app -e
    if ( -not ( $found -match $app )){
        Write-Host "Installing $app" -ForegroundColor yellow
        winget install --id=$app -e
    }
    else {
        Write-Host "$app already installed"
    }
}


<#
 Spotify.Spotify
#>

