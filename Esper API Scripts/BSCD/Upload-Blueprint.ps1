<###############################################################################
#################### Base Connection Variables for Esper API #######################
################################################################################>

# Set your Esper tenant, Enterprise ID, and API key
$tenant = "BSCD"
# API Key from esprbst (BSCD)
$apiKey = "ba6Lj09t5AJ6bl1ykvsSOMJqUjSv9Q"
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
$blueprintName = "DSA Master"
$blueprintSettings = "$response.content.settings.android"
$body = @{
    name = ""
    settings = ""
} | ConvertTo-Json -Depth 100
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
$response