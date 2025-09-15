<###################################################################################
#################### Base Connection Variables for Esper API #######################
###################################################################################>

# Set your Esper tenant, Enterprise ID, and API key
$tenant = "dillardstest"
# API Key from esprbst (dillardstest)
$apiKey = "tdlBj7tuv43apEsJn863lSAyBDGBcx"

# Base API URL
$baseUri = "https://$tenant-api.esper.cloud/api/v2/devices"
$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}
<#------------------------------------------------------------------------------
################################################################################
#################### END Base Connection Variables for Esper API ###############
################################################################################
------------------------------------------------------------------------------#>

$uri = "$baseUri/?limit=50000"
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
$response.content