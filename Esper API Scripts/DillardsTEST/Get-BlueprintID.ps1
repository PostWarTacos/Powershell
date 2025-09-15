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
#$blueprintName = "DSA Master"
$blueprintName = Read-Host -Prompt "Enter Blueprint Name"
$uri = "$baseUri/?name=$blueprintName"
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
$blueprintID = $response.content.results | Select-Object -ExpandProperty id
$blueprintID
Set-Clipboard -Value "$blueprintID"
Write-Host "Blueprint ID Copied to Clipboard"
Read-Host -Prompt "Press Enter to Exit"