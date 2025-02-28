$myPC = "cshaw002"
$uri = "https://ssdcorpappsrvt1.dpos.loc/esper/Device/AllStores"
$header = @{"accept" = "text/plain"}
$web = Invoke-WebRequest -Uri $uri -Headers $header
$db = $web.content | ConvertFrom-Json
$site = $db | select storeNumber,siteCode,ipSubnet,timeZone | where sitecode -eq ($(hostname).substring(1,4))
$site  