If ( whoami -like "*wurtzmt*" ){
    $user = "C:\users\wurtzmt"
} 
Else {
    $user = [System.Environment]::GetFolderPath("UserProfile")
}

$SharedProfilePath = "$user\Documents\Coding\PowerShell\PS-Management\PowerShellProfile\Main Profile\MinimumProfile.ps1"
$DotSourceLine = ". '$SharedProfilePath'"

$AllProfiles = @(
    $PROFILE.AllUsersAllHosts,
    $PROFILE.AllUsersCurrentHost,
    $PROFILE.CurrentUserAllHosts,
    $PROFILE.CurrentUserCurrentHost
)

# Also add ISE specific path
$ISEProfile = "$user\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1"
if ( -not ( Test-Path $ISEProfile )) { New-Item -ItemType File -Path $ISEProfile -Force }
$AllProfiles += $ISEProfile

foreach ( $profilePath in $AllProfiles | Sort-Object -Unique ) {
    if ( -not ( Test-Path $profilePath )) {
        New-Item -ItemType File -Path $profilePath -Force
    }

    $content = Get-Content $profilePath -Raw

    if ( $content -notmatch [regex]::Escape( $DotSourceLine )) {
        Add-Content -Path $profilePath -Value "`n$DotSourceLine"
        Write-Host "Linked: $profilePath"
    } else {
        Write-Host "Already linked: $profilePath"
    }
}
