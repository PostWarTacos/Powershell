<###############################################################################
#################### Base Connection Variables for Esper API #######################
################################################################################>

# Set your Esper tenant, Enterprise ID, and API key
$tenant = "dillardstest"
$enterpriseID = "91593785-864a-4895-b872-fe845c279fa3"
$apiKey = "tdlBj7tuv43apEsJn863lSAyBDGBcx"

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