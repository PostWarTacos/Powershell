<###############################################################################
#################### Base Connection Variables for Esper API #######################
################################################################################>

# Set your Esper tenant, Enterprise ID, and API key
$tenant = "BSCD"
$enterpriseID = "a0279b84-ff6b-413b-bb52-2041690503a6"
$apiKey = "ba6Lj09t5AJ6bl1ykvsSOMJqUjSv9Q"

# Base API URL
$baseUri = "https://$tenant-api.esper.cloud/api/enterprise/$EnterpriseID"
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

$uri = "$baseUri/devicegroup/?limit=50000"
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
$response.results