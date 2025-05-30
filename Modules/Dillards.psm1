﻿Function Get-SiteInfoFromDDSAPI() {
    [CmdletBinding(DefaultParameterSetName = 'ByHostname')]
    param (
        # --- Set 1 ---
        [Parameter(ParameterSetName = 'ByHostname', Mandatory = $true)]
        [string]$Hostname,
        
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
            $localCode = $($Hostname).substring(1,4)
            $result = $db | Where-Object SiteCode -eq $localCode
        }
        'ByStore' {
            $result = $db | Where-Object StoreNumber -eq $StoreNumber
        }
        'BySite' {
            $result = $db | Where-Object SiteCode -eq $SiteCode
        }
    }

    $result | Select-Object StoreNumber, SiteCode, Division, StoreType, Timezone
}

Export-ModuleMember Get-SiteInfoFromDDSAPI