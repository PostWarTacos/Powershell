<###############################################################################
#################### Base Connection Variables for Dillard's API ###############
################################################################################>

$dillardUri = "https://ssdcorpappsrvt1.dpos.loc/esper/Device/AllStores"
$headers = @{
   "Content-Type" = "application/json"
    "Accept" = "application/json"
}
$db = Invoke-RestMethod -Uri $dillardUri -Headers $headers -Method Get
<#----------------------------------------------------------------------------------
<###################################################################################
#################### END Base Connection Variables for Dillard's API ###############
####################################################################################
-----------------------------------------------------------------------------------#>

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

# Get Esper device groups
$esperUri = "$baseUri/devicegroup/"
$response = Invoke-RestMethod -Uri $esperuri -Headers $headers -Method Get

# Query store numbers from Dillard's API
$stnums = $db | Where-Object {$_.storeNumber -notmatch "00"} | Select-Object -ExpandProperty storeNumber

# Loop through all locations from Dillard's API
foreach($store in $stnums){
    # Set variables 
    $stinfo = $db | Where-Object {($_.storeNumber -match "$store")-and($_.storeNumber -notmatch "00")}
    $siteCode = $stinfo.siteCode
    $timeZone = $stinfo.timeZone
    $storeShort = $store -replace "^0+", ""
    $groupShort = "$siteCode"+"-"+"$storeShort"
    $groupRole = @("DSA", "AIO", "PCH")
    foreach ($role in $groupRole) {
        $groupLong = "$role"+"-"+$groupShort
# Check if device group exists in Esper
$esperExists = $response.results | Where-Object { $_.name -like "$groupLong" }
    # If device group doesn't exist, proceed with creation    
    if(!($esperExists)){
        # If store has time zone set to "Pacific" in Dillard's API, create Esper subgroups under "Pacific (Time Zone)" parent group
        if ($timeZone -eq "Pacific") {
            $parentID = "e3d7bc30-38d3-4c10-bb19-baba5d84f64b"
            $body = @{
                name = "$groupLong"
                parent = "$parentID"
            } | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri $esperUri -Headers $headers -Method Post -Body $body
            Write-Host "Creating $groupLong (Pacific)"
        }
        # If store has time zone set to "Mountain" in Dillard's API, create Esper subgroups under "Mountain (Time Zone)" parent group
        elseif ($timeZone -eq "Mountain") {
            $parentID = "af192925-891b-42fe-9c1e-f67f7597d538"
            $body = @{
                name = "$groupLong"
                parent = "$parentID"
            } | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri $esperUri -Headers $headers -Method Post -Body $body
            Write-Host "Creating $groupLong (Mountain)"
        }
        # If store has time zone set to "Central" in Dillard's API, create Esper subgroups under "Central (Time Zone)" parent group
        elseif ($timeZone -eq "Central") {
            $parentID = "1b9a2bc5-42cf-46d8-8b7b-26bfe31b1618"
            $body = @{
                name = "$groupLong"
                parent = "$parentID"
            } | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri $esperUri -Headers $headers -Method Post -Body $body
            Write-Host "Creating $groupLong (Central)"
        }
        # If store has time zone set to "Eastern" in Dillard's API, create Esper subgroups under "Eastern (Time Zone)" parent group
        elseif ($timeZone -eq "Eastern") {
            $parentID = "9721e68d-00d1-455f-abf8-d42e2c5fce98"
            $body = @{
                name = "$groupLong"
                parent = "$parentID"
            } | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri $esperUri -Headers $headers -Method Post -Body $body
            Write-Host "Creating $groupLong (Eastern)"
        }
        # If store has time zone set to "Arizona" in Dillard's API, create Esper subgroups under "Arizona (Time Zone)" parent group
        elseif ($timeZone -eq "Arizona") {
            $parentID = "9dd8be1f-e2df-4307-aa93-bce272550381"
            $body = @{
                name = "$groupLong"
                parent = "$parentID"
            } | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri $esperUri -Headers $headers -Method Post -Body $body
            Write-Host "Creating $groupLong (Arizona)"
        }
    }    
    }
}