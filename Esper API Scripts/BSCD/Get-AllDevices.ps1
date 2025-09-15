<###################################################################################
#################### Base Connection Variables for Esper API #######################
###################################################################################>

# Set your Esper tenant, Enterprise ID, and API key
$tenant = "BSCD"
# API Key from esprbst (BSCD)
$apiKey = "ba6Lj09t5AJ6bl1ykvsSOMJqUjSv9Q"

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