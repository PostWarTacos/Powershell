Function Get-SiteInfoFromDDSAPI() {
    [CmdletBinding(DefaultParameterSetName = 'ByHostname')]
    param (
        # --- Set 1 ---
        [Parameter(ParameterSetName = 'ByHostname', Mandatory = $true)]
        [switch]$UseLocalHostname,
        
        # --- Set 2 ---
        [Parameter(ParameterSetName = 'ByStore', Mandatory = $true)]
        [int]$StoreNumber,

        # --- Set 3 ---
        [Parameter(ParameterSetName = 'BySite', Mandatory = $true)]
        [string]$SiteCode
    )

    $uri = "https://ssdcorpappsrvt1.dpos.loc/esper/Device/AllStores"
    $header = @{"accept" = "text/plain"}
    $web = Invoke-WebRequest -Uri $uri -Headers $header
    $db = $web.content | ConvertFrom-Json

    switch ($PSCmdlet.ParameterSetName) {
        'ByHostname' {
            $siteCode = $(hostname).substring(1,4)
            $result = $db | Where-Object SiteCode -eq $siteCode
        }
        'ByStore' {
            $result = $db | Where-Object StoreNumber -eq $StoreNumber
        }
        'BySite' {
            $result = $db | Where-Object SiteCode -eq $SiteCode
        }
    }

    $result | Select-Object StoreNumber, SiteCode, Region, Timezone, Manager
}

Export-ModuleMember Get-SiteInfoFromDDSAPI