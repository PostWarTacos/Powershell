<###################################################################################
#################### Base Connection Variables for Esper API #######################
###################################################################################>

# Set your Esper tenant, Enterprise ID, and API key
$tenant = "dillardstest"
# API Key from esprbst (dillardstest)
$apiKey = "tdlBj7tuv43apEsJn863lSAyBDGBcx"

# Base API URL
$baseUri = "https://$tenant-api.esper.cloud/api/commands/v0/commands"
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
$contentID = "37"
$contentDestinationPath = "/storage/emulated/0/Downloads"
$contentName = "test.txt"
$deviceIDs = @("e980d71d-cc54-4d23-9576-4c065c0b4765")
$groupIDs = @()


$body = @{
    command_type = "DEVICE"
    devices = $deviceIDs
    groups = $groupIDs
    device_type = "all"
    command = "SYNC_CONTENT"
    command_args = @{
        kind = "DOWNLOAD_CONTENT"
        content_id = $contentID
        content_destination_path = $contentDestinationPath
        content_destination_type = "external"
        ui_content_name = $contentName

    }
} | ConvertTo-Json -Depth 10
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
$response
