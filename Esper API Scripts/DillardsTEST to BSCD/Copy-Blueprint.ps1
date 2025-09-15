<##################################################################################################
#################### Base Connection Variables for Esper API (dillardsTEST) #######################
##################################################################################################>

# Set your Esper tenant, Enterprise ID, and API key
$testTenant = "dillardstest"
# API Key from esprbst (dillardstest)
$testApiKey = "tdlBj7tuv43apEsJn863lSAyBDGBcx"

# Base API URL
$testBaseUri = "https://$testTenant-api.esper.cloud/api/v2/blueprints"
$testHeaders = @{
    "Authorization" = "Bearer $testApiKey"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}
<#---------------------------------------------------------------------------------------------
###############################################################################################
#################### END Base Connection Variables for Esper API (dillardsTEST) ###############
###############################################################################################
---------------------------------------------------------------------------------------------#>

<##################################################################################################
#################### Base Connection Variables for Esper API (BSCD) ###############################
##################################################################################################>

# Set your Esper tenant, Enterprise ID, and API key
$BSCDTenant = "BSCD"
# API Key from esprbst (BSCD)
$BSCDApiKey = "ba6Lj09t5AJ6bl1ykvsSOMJqUjSv9Q"

# Base API URL
$BSCDBaseUri = "https://$BSCDTenant-api.esper.cloud/api/v2/blueprints/"
$BSCDHeaders = @{
    "Authorization" = "Bearer $BSCDApiKey"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}
<#-------------------------------------------------------------------------------------
#######################################################################################
#################### END Base Connection Variables for Esper API (BSCD) ###############
#######################################################################################
-------------------------------------------------------------------------------------#>

$blueprintName = Read-Host -Prompt "Enter Blueprint Name"
$testUri = "$testBaseUri/?name_exact=$blueprintName"
$testResponse = Invoke-RestMethod -Uri $testUri -Headers $testHeaders -Method Get
$blueprintID = $testResponse.content.results | Select-Object -ExpandProperty id
$testUri = "$testBaseUri/$blueprintID/"
$testResponse = Invoke-RestMethod -Uri $testUri -Headers $testHeaders -Method Get
$blueprintSettings = $testResponse.content.settings
# | ConvertFrom-Json


$BSCDUri = "$BSCDBaseUri"
$BSCDBody = @{
    name = "DSA Master (DEV)"
    settings = $blueprintSettings
} | ConvertTo-Json -Depth 100
$BSCDResponse = Invoke-RestMethod -Uri $BSCDUri -Headers $BSCDHeaders -Method Post -Body $BSCDBody
$BSCDResponse