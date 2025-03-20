<#
#   Intent: Pulls computer name and queries db built in SSDS for siteCode, subnet, stNum, and timezone
#   Author: Matthew Wurtz
#   Date: 28-Feb-25
#>


$uri = "https://ssdcorpappsrvt1.dpos.loc/esper/Device/AllStores"
$header = @{"accept" = "text/plain"}
$web = Invoke-WebRequest -Uri $uri -Headers $header
$db = $web.content | ConvertFrom-Json

$output = @()

$list = "ctrip207"
foreach ( $pc in $list ){
    $site = $db | select storeNumber,siteCode,ipSubnet,timeZone | where sitecode -eq $pc.substring(1,4)
    $output += [PSCustomObject]@{ComputerName=$pc; SiteCode=$site.siteCode; StoreNumber=$site.storeNumber; Timezone=$site.timeZone}
}

$output #| Export-Csv C:\Users\wurtzmt\Desktop\corrupt.csv