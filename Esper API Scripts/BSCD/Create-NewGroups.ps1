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
            $parentID = "9348f0e9-7943-438c-95ba-0db2b8156a31"
            $body = @{
                name = "$groupLong"
                parent = "$parentID"
            } | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri $esperUri -Headers $headers -Method Post -Body $body
            Write-Host "Creating $groupLong (Pacific)"
        }
        # If store has time zone set to "Mountain" in Dillard's API, create Esper subgroups under "Mountain (Time Zone)" parent group
        elseif ($timeZone -eq "Mountain") {
            $parentID = "89b7545c-1a33-4d16-9f3d-81d57e3edd3b"
            $body = @{
                name = "$groupLong"
                parent = "$parentID"
            } | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri $esperUri -Headers $headers -Method Post -Body $body
            Write-Host "Creating $groupLong (Mountain)"
        }
        # If store has time zone set to "Central" in Dillard's API, create Esper subgroups under "Central (Time Zone)" parent group
        elseif ($timeZone -eq "Central") {
            $parentID = "4e1963b1-8e27-4992-8e06-48b77a3b7bea"
            $body = @{
                name = "$groupLong"
                parent = "$parentID"
            } | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri $esperUri -Headers $headers -Method Post -Body $body
            Write-Host "Creating $groupLong (Central)"
        }
        # If store has time zone set to "Eastern" in Dillard's API, create Esper subgroups under "Eastern (Time Zone)" parent group
        elseif ($timeZone -eq "Eastern") {
            $parentID = "7503f77b-a061-440e-b725-834848779eac"
            $body = @{
                name = "$groupLong"
                parent = "$parentID"
            } | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri $esperUri -Headers $headers -Method Post -Body $body
            Write-Host "Creating $groupLong (Eastern)"
        }
        # If store has time zone set to "Arizona" in Dillard's API, create Esper subgroups under "Arizona (Time Zone)" parent group
        elseif ($timeZone -eq "Arizona") {
            $parentID = "3524a7ea-2028-49d1-a901-7ace26f507e7"
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