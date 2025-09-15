<###################################################################################
#################### Base Connection Variables for Esper API #######################
###################################################################################>

# Set your Esper tenant, Enterprise ID, and API key
$tenant = "dillardstest"
$enterpriseID = "91593785-864a-4895-b872-fe845c279fa3"
# API Key from esprbst (dillardstest)
$apiKey = "tdlBj7tuv43apEsJn863lSAyBDGBcx"

# Base API URL
#$baseUriOld = "https://$tenant-api.esper.cloud/api/v2/subgroups"
$baseUriNew = "https://$tenant-api.esper.cloud/api/enterprise/$enterpriseID"
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

$parentGroupID = Read-Host -Prompt "Enter Parent Group ID(s)"
#$uriOld = "$baseUri/?parent_group_ids=$parentGroupID"
$uriNew = "$baseUriNew/devicegroup/?parent=$parentGroupID"
#$responseOld = Invoke-RestMethod -Uri $uriOld -Headers $headers -Method Get
$responseNew = Invoke-RestMethod -Uri $uriNew -Headers $headers -Method Get
#$responseOld.content
$responseNew.results