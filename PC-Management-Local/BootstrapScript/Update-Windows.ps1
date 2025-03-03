# Run as Administrator

# Set Feature Updates Deferral (365 days)
Write-Host "Setting Windows Update feature update deferral to 1 year..." -ForegroundColor Cyan
$FeatureDeferralDays = 365
$QualityDeferralDays = 0  # Security updates are not delayed

# Apply Windows Update Deferral via Registry
$RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
If (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force }

Set-ItemProperty -Path $RegPath -Name "DeferFeatureUpdates" -Value 1 -Type DWord
Set-ItemProperty -Path $RegPath -Name "DeferFeatureUpdatesPeriodInDays" -Value $FeatureDeferralDays -Type DWord
Set-ItemProperty -Path $RegPath -Name "DeferQualityUpdates" -Value 0 -Type DWord
Set-ItemProperty -Path $RegPath -Name "DeferQualityUpdatesPeriodInDays" -Value $QualityDeferralDays -Type DWord

# Prevent Feature Updates via Group Policy
$GP_Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
Set-ItemProperty -Path $GP_Path -Name "BranchReadinessLevel" -Value 48 -Type DWord  # Semi-Annual Channel
Set-ItemProperty -Path $GP_Path -Name "PauseFeatureUpdates" -Value 0 -Type DWord
Set-ItemProperty -Path $GP_Path -Name "PauseQualityUpdates" -Value 0 -Type DWord

# Prevent Feature Updates from being downloaded automatically
$AU_Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
If (!(Test-Path $AU_Path)) { New-Item -Path $AU_Path -Force }
Set-ItemProperty -Path $AU_Path -Name "AUOptions" -Value 2 -Type DWord  # Notify for download and install
Set-ItemProperty -Path $AU_Path -Name "NoAutoUpdate" -Value 0 -Type DWord  # Keep updates enabled
Set-ItemProperty -Path $AU_Path -Name "AllowMUUpdateService" -Value 1 -Type DWord  # Allow Microsoft Update

# Force Group Policy Update
Write-Host "Forcing Group Policy Update..." -ForegroundColor Yellow
gpupdate /force

Write-Host "Windows Update settings have been configured to defer feature updates for 1 year while allowing security updates." -ForegroundColor Green
