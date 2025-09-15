<###################################################################################
#################### Base Connection Variables for Esper API #######################
###################################################################################>

# Set your Esper tenant, Enterprise ID, and API key
$tenant = "dillardstest"
# API Key from esprbst (dillardstest)
$apiKey = "tdlBj7tuv43apEsJn863lSAyBDGBcx"

# Base API URL
$baseUri = "https://$tenant-api.esper.cloud/api/device/v0/devices"
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
$uri = "$baseUri/"
#$uri = "$baseUri/?search=Honeywell"
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
#$response.content.results
$devices = $response.content.results
$devicesNoAlias = $devices | Where-Object {[string]::IsNullOrWhiteSpace($_.Alias)} | Select-Object Name
