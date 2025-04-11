If ( $(whoami) -match "wurtzmt" ){
    $user = "C:\users\wurtzmt"
} 
Else {
    $user = [System.Environment]::GetFolderPath("UserProfile")
}

$SharedProfilePath = "$user\Documents\Coding\PowerShell\PS-Management\PowerShellProfile\Main Profile\MinimumProfile.ps1"
$DotSourceLine = ". '$SharedProfilePath'"

# Ensure Admin Privileges
if ( -not ( [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent() ).IsInRole( [Security.Principal.WindowsBuiltinRole] "Administrator" )) {
    Write-Warning "This script must be run as Administrator. Exiting."
    exit 1
}

# Build list of all profile paths across versions/hosts
$AllProfiles = @(
    $PROFILE.AllUsersAllHosts,
    $PROFILE.AllUsersCurrentHost,
    $PROFILE.CurrentUserAllHosts,
    $PROFILE.CurrentUserCurrentHost,
    "$user\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
    "$user\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1",
    "$user\Documents\PowerShell\Microsoft.VSCode_profile.ps1"  # optional
) | Sort-Object -Unique

# Step 1: Delete all existing profile files
foreach ( $profile in $AllProfiles ) {
    if ( Test-Path $profile ) {
        try {
            Remove-Item -Path $profile -Force
            Write-Host "Deleted existing profile: $profile" -ForegroundColor Yellow
        } catch {
            Write-Warning "Could not delete $profile`: $_"
        }
    }
}

# Step 2: Create fresh profile files with dot-source line
foreach ($profilePath in $AllProfiles) {
    try {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
        Add-Content -Path $profilePath -Value "`n$DotSourceLine"
        Write-Host "Created new profile and linked shared file: $profilePath" -ForegroundColor Green
    } catch {
        Write-Warning "Could not create or write to $profilePath`: $_"
    }
}
