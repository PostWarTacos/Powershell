<###############################################################################
#################### Base Connection Variables for Esper API #######################
################################################################################>

# Set your Esper tenant, Enterprise ID, and API key
$tenant = "dillardstest"
# API Key from esprbst (dillardstest)
$apiKey = "tdlBj7tuv43apEsJn863lSAyBDGBcx"
# Base API URL
$baseUri = "https://$tenant-api.esper.cloud/api/v2/blueprints/"
$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}
<#------------------------------------------------------------------------------
################################################################################
#################### END Base Connection Variables for Esper API ###############
################################################################################
-------------------------------------------------------------------------------#>

$uri = "$baseUri"
$blueprintName = "DSA Master (Test)"
$blueprintSettings = Get-Content "~/Downloads/DSA Master.json"
$blueprintSettingsPSObject = $blueprintSettings | ConvertFrom-Json
$body = @{
    name = "$blueprintName"
    settings = $blueprintSettingsPSObject
} | ConvertTo-Json -Depth 100
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
$response