<###################################################################################
#################### Base Connection Variables for Esper API #######################
###################################################################################>
clear
# Set your Esper tenant, Enterprise ID, and API key
$tenant = "BSCD"
$enterpriseID = "a0279b84-ff6b-413b-bb52-2041690503a6"
# API Key from esprbst (BSCD)
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
------------------------------------------------------------------------------#>
$i = 0
clear
do{
    $groupName = Read-Host -Prompt "Enter Group Name"
    $uri = "$baseUri/devicegroup/?name=$groupName"
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    $output = $response.results | where name -match dsa | Select-Object -Property name, id
    $output.ID
    Set-Clipboard $output.ID
    $i++
} Until ( $i -eq 100)