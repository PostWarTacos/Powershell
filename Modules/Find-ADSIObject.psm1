function Find-ADSIObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("Computer", "User", "Group", "OU")]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Name
    )

    # Map LDAP filters for each type
    switch ($Type) {
        "Computer" {
            $filter = "(&(objectClass=computer)(sAMAccountName=$Name`$))"
        }
        "User" {
            $filter = "(&(objectClass=user)(sAMAccountName=$Name))"
        }
        "Group" {
            $filter = "(&(objectClass=group)(sAMAccountName=$Name))"
        }
        "OU" {
            $filter = "(&(objectClass=organizationalUnit)(ou=$Name))"
        }
    }

    $searcher = [ADSISearcher]::new($filter)
    $result = $searcher.FindOne()

    if ($result -and $result.Properties["adspath"]) {
        return [ADSI]$result.Properties["adspath"][0]
    } else {
        Write-Warning "$Type '$Name' not found in AD."
        return $null
    }
}
