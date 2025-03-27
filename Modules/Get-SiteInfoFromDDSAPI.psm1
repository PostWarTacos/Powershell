Function Get-FileName() {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$SiteCode,
        
        [Parameter()]
        [int]$storenumber
    )

    $uri = "https://ssdcorpappsrvt1.dpos.loc/esper/Device/AllStores"
    $header = @{"accept" = "text/plain"}
    $web = Invoke-WebRequest -Uri $uri -Headers $header
    $db = $web.content | ConvertFrom-Json
    $site = $db | Select-Object storeNumber,siteCode,ipSubnet,timezone | Where-Object sitecode -eq ($(hostname).substring(1,4))
    $site

}